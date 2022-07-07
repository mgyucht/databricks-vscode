from typing import Iterator
from itertools import chain
from functools import cache
import glob
import os
import re
import sys

import click
from jinja2 import Environment
from jinja2 import FileSystemLoader
import json


SEPARATOR = '.'


def camel_to_snake(name):
    name = re.sub('(.)([A-Z][a-z]+)', r'\1_\2', name)
    return re.sub('([a-z0-9])([A-Z])', r'\1_\2', name).lower()


def transform_full_path(path):
    """
    Warning, hack!
    Turn internal path `managedLibraries.ZZZ` into publicly documented path `libraries.ZZZ`.
    This transformation should be done in universe at an earlier processing step.
    """
    if path[0] == 'managedLibraries':
        path[0] = 'libraries'
    return path


def transform_field_type(name):
    return SEPARATOR.join(transform_full_path(name.split('.')))


@cache
def databricks_cli_compat_file():
    path = os.path.expanduser("~/dev/databricks-cli/tests/test_compat.json")
    path = os.path.expanduser("~/dev/eng-dev-ecosystem/api/tmp/test_compat.json")
    if not os.path.exists(path):
        raise RuntimeError(
            f"""
            Expected to find the Databricks CLI argument compatibility file at: {path}.
            Make sure you have the Databricks CLI repository checked out at
            {os.path.expanduser("~/dev/databricks-cli")} and that the PR that
            introduces the compatibility file (#507) has been merged.
            """
        )
    with open(path, 'r', encoding='utf-8') as f:
        return json.load(f)


def databricks_cli_compat_args(key):
    return databricks_cli_compat_file().get(key)


class Field:
    def __init__(self, message: 'Message', obj):
        self.message = message
        self.obj = obj

    def name(self) -> str:
        return self.obj['field_name']

    def entity_type(self) -> str:
        return self.obj['entity_type']

    def is_message_type(self) -> bool:
        return not self.obj['repeated'] and self.entity_type().lower() == 'message'

    def field_type(self) -> str:
        return transform_field_type(self.obj['field_type'])

    def field_type_basename(self) -> str:
        return self.field_type().split('.')[-1]

    def is_required(self) -> bool:
        return self.obj['validate_required']

    def js_type(self, scope: 'Scope') -> str:
        def primitive():
            typ = self.field_type()
            if typ == 'INT32':
                return 'number'
            elif typ == 'INT64':
                return 'number'
            elif typ == 'STRING':
                return 'string'
            elif typ == 'FLOAT':
                return 'number'
            elif typ == 'DOUBLE':
                return 'number'
            elif typ == 'BOOL':
                return 'boolean'
            elif typ == 'BYTES':
                return 'string'

            path = typ.split('.')
            if scope.in_scope(typ):
                if path in [message.full_path() for message in scope.request_messages()]:
                    return path[-1] + "Request"
                return path[-1]
            else:
                return path[0] + '.' + path[-1]

        if self.obj['repeated']:
            return f"Array<{primitive()}>"
        else:
            return primitive()


class Method:
    def __init__(self, service: 'Service', obj):
        self.service = service
        self.obj = obj

    def name(self) -> str:
        return self.obj['name']

    def sanitized_name(self) -> str:
        if self.service.name() == 'WorkspaceService':
            if self.name() == 'import':
                return 'import_workspace'
            if self.name() == 'export':
                return 'export_workspace'
        return self.name()

    def name_snake(self) -> str:
        return camel_to_snake(self.sanitized_name())

    def full_path(self) -> list[str]:
        return transform_full_path(self.obj['full_path'])

    def description(self) -> str:
        return self.obj['description']

    def request_full_path(self) -> str:
        return SEPARATOR.join(transform_full_path(self.obj['request_full_path']))

    def request_message(self) -> 'Message':
        return self.service.file.doc_file.messages()[self.request_full_path()]

    def request_payload_fields(self) -> list[Field]:
        url_field_names = set(self.url_field_names())
        return [
            f
            # Order required fields before optional fields.
            for f in self.request_message().required_fields()
            + self.request_message().optional_fields()
            if f.name() not in url_field_names
        ]

    def request_url_fields(self) -> list[Field]:
        url_field_names = set(self.url_field_names())
        return [f for f in self.request_message().fields() if f.name() in url_field_names]

    def response_full_path(self) -> str:
        return SEPARATOR.join(transform_full_path(self.obj['response_full_path']))

    def response_message(self) -> 'Message':
        return self.service.file.doc_file.messages()[self.response_full_path()]

    def rpc_options(self) -> dict:
        return self.obj['rpc_options']

    @cache
    def url_field_names(self) -> list[str]:
        """
        Return fields that should be interpolated in the URL path.
        """
        return re.findall("\{(\w+)\}", self.rpc_options()['path'])


class BaseType:
    def __init__(self, file: 'File', obj):
        self.file = file
        self.obj = obj

    def name(self) -> str:
        return self.obj['name']

    def full_path(self) -> list[str]:
        return transform_full_path(self.obj['full_path'])

    def full_path_str(self) -> str:
        return SEPARATOR.join(self.full_path())

    def description(self) -> str:
        return self.obj['description']

    def visibility(self) -> str:
        return self.obj['visibility']


class Enum(BaseType):
    def __init__(self, file, obj):
        super().__init__(file, obj)

    def values(self) -> list[str]:
        return [obj['value'] for obj in self.obj['values']]


class Message(BaseType):
    def __init__(self, file, obj):
        super().__init__(file, obj)

    def fields(self):
        return [Field(self, o) for o in self.obj['fields']]

    def required_fields(self):
        return [f for f in self.fields() if f.is_required()]

    def optional_fields(self):
        return [f for f in self.fields() if not f.is_required()]

    def messages(self) -> Iterator['Message']:
        messages = [[self]]
        for obj in self.obj['messages']:
            messages.append(Message(self, obj).messages())
        return chain(*messages)

    def databricks_cli_ordered_fields(self, method: Method) -> list[Field]:
        fields = {f.name(): f for f in self.required_fields() + self.optional_fields()}
        args = [arg.split('=', 2)[0] for arg in self.databricks_cli_ordered_args(method, [])]
        return [fields.get(arg) for arg in args if arg in fields]

    def databricks_cli_ordered_args(self, method: Method, tail: list[str]) -> list[str]:
        required_arguments = [f.name() for f in self.required_fields()]
        optional_arguments = [f.name() for f in self.optional_fields()]

        # Pull args from compat file.
        key = f"databricks_cli.sdk.service.{method.service.name()}.{method.name_snake()}"
        output = ['self']
        args = databricks_cli_compat_args(key)
        if args:
            # Remove 'self'.
            args = args[1:]

            # Nobody can add required fields.
            assert (
                required_arguments == args[0 : len(required_arguments)]
            ), "Found additional required arguments; this is not allowed!"

        # Add required arguments.
        output.extend(required_arguments)

        # Add pre-existing optional arguments.
        if args:
            for arg in args[len(required_arguments) :]:
                output.append(f"{arg}=None")
                if arg in optional_arguments:
                    optional_arguments.remove(arg)
                if arg in tail:
                    tail.remove(arg)

        # Add remaining optional arguments
        for arg in optional_arguments:
            output.append(f"{arg}=None")

        # Add remaining tail arguments
        for arg in tail:
            output.append(f"{arg}=None")

        return output


class Service(BaseType):
    def __init__(self, file, obj):
        super().__init__(file, obj)

    def methods(self) -> Iterator[Method]:
        methods = [Method(self, o) for o in self.obj['methods']]
        return methods

    def sanitize_method_name(self, name: str):
        index = self.name().rindex('Service')
        base = self.name()[0:index]
        if name.endswith(base):
            return name[0 : -len(base)]
        return name

    def request_messages(self) -> Iterator[Message]:
        return [m.request_message() for m in self.methods()]

    def response_messages(self) -> Iterator[Message]:
        return [m.response_message() for m in self.methods()]

    def request_response_messages(self) -> Iterator[Message]:
        return chain(
            [m.request_message() for m in self.methods()],
            [m.response_message() for m in self.methods()],
        )


class File:
    def __init__(self, doc_file: 'DocFile', obj):
        self.doc_file = doc_file
        self.obj = obj

    def filename(self) -> str:
        return self.obj['filename']

    def requested_visibility(self) -> str:
        return self.obj['requested_visibility']

    def enums(self) -> Iterator[Enum]:
        for obj in self.obj['content']:
            if obj['enum']:
                yield Enum(self, obj['enum'])

    def messages(self) -> Iterator[Message]:
        messages = []
        for obj in self.obj['content']:
            if obj['message']:
                messages.append(Message(self, obj['message']).messages())
        return chain(*messages)

    def services(self) -> Iterator[Service]:
        for obj in self.obj['content']:
            if obj['service']:
                yield Service(self, obj['service'])


class Scope:
    """
    This is not encoded in the file. It captures the set of enums, messages, services at a path.
    """

    def __init__(self, doc_file: 'DocFile', path: list[str]):
        self.doc_file = doc_file
        self.path = path

    def in_scope(self, path: str):
        path_parts = path.split('.')
        return path_parts[0 : len(self.path)] == self.path

    def _filter(self, it: Iterator[BaseType]) -> Iterator[BaseType]:
        return [el for el in it if el.full_path()[0 : len(self.path)] == self.path]

    @cache
    def enums(self):
        return self._filter(self.doc_file.enums().values())

    @cache
    def messages(self):
        return self._filter(self.doc_file.messages().values())

    @cache
    def services(self):
        return self._filter(self.doc_file.services().values())

    @cache
    def request_messages(self) -> list[Message]:
        return [message for service in self.services() for message in service.request_messages()]

    @cache
    def response_messages(self) -> list[Message]:
        return [message for service in self.services() for message in service.response_messages()]

    @cache
    def request_response_messages(self) -> list[Message]:
        return [
            message
            for service in self.services()
            for message in service.request_response_messages()
        ]


class DocFile:
    def __init__(self, path):
        with open(path) as f:
            self.obj = json.load(f)

    def requested_visibility(self) -> str:
        return self.obj['requested_visibility']

    @cache
    def files(self) -> list[File]:
        return [File(self, obj) for obj in self.obj['files']]

    @cache
    def messages(self) -> dict[str, Message]:
        return {o.full_path_str(): o for file in self.files() for o in file.messages()}

    @cache
    def enums(self) -> dict[str, Enum]:
        return {o.full_path_str(): o for file in self.files() for o in file.enums()}

    @cache
    def services(self) -> dict[str, Service]:
        return {o.full_path_str(): o for file in self.files() for o in file.services()}


def jinja_env(paths=[]):
    jinja_paths = [os.path.join(os.getcwd())] + [os.path.join(os.getcwd(), path) for path in paths]
    env = Environment(loader=FileSystemLoader(jinja_paths))
    env.globals.update(camel_to_snake=camel_to_snake)
    env.trim_blocks = True
    env.lstrip_blocks = True
    return env


@click.group()
def main():  # pragma: no cover
    pass


@click.command(name="generate")
@click.option("--doc-file", "doc_file_path", required=True, envvar='DOC_FILE_JSON')
@click.option("--template", required=True)
@click.option("--output")
def generate_command(doc_file_path, template, output):
    doc_file = DocFile(doc_file_path)

    def get_scope(path: list[str]):
        return Scope(doc_file, path)

    def render_file(template):
        template = jinja_env(paths=[os.path.dirname(template)]).get_template(template)
        return template.render(
                services=doc_file.services(),
                enums=doc_file.enums(),
                messages=doc_file.messages(),
                get_scope=get_scope,
            )

    if os.path.isfile(template):
        print(render_file(template))
    elif os.path.isdir(template):
        if output is None:
            click.echo("Please specify --output if --template points to directory.")
            sys.exit(1)
        for file in glob.glob(f"{template}/*.jinja2"):
            basefile = os.path.basename(file)
            if not re.match('^[a-z]', basefile):
                continue
            name, _ = os.path.splitext(basefile)
            with open(os.path.join(output, name), 'w', encoding='utf-8') as f:
                f.write(render_file(file))


@click.command(name="get")
@click.option("--doc-file", "doc_file_path", required=True, envvar='DOC_FILE_JSON')
@click.option("--comment", "comment_path")
@click.option("--enum", "enum_path")
@click.option("--message", "message_path")
@click.option("--service", "service_path")
def get_command(doc_file_path, comment_path=None, enum_path=None, message_path=None, service_path=None):
    doc_file = DocFile(doc_file_path)
    if comment_path is not None:
        return
    if enum_path is not None:
        json.dump(doc_file.enums()[enum_path].obj, sys.stdout)
        return
    if message_path is not None:
        json.dump(doc_file.messages()[message_path].obj, sys.stdout)
        return
    if service_path is not None:
        json.dump(doc_file.services()[service_path].obj, sys.stdout)
        return
    return


@click.command(name="list")
@click.option("--doc-file", "doc_file_path", required=True, envvar='DOC_FILE_JSON')
@click.option("--scope", "scope", type=str)
@click.option("--comments", is_flag=True, show_default=False)
@click.option("--enums", is_flag=True, show_default=False)
@click.option("--messages", is_flag=True, show_default=False)
@click.option("--services", is_flag=True, show_default=False)
def list_command(doc_file_path, scope, comments, enums, messages, services):
    doc_file = DocFile(doc_file_path)

    # Scope listing to proto path specified by `scope`.
    scoped = Scope(doc_file, scope.split('.') if scope else [])
    if comments:
        pass
    if enums:
        for enum in scoped.enums():
            print(enum.full_path_str())
    if messages:
        for message in scoped.messages():
            print(message.full_path_str())
    if services:
        for service in scoped.services():
            print(service.full_path_str())


if __name__ == '__main__':
    main.add_command(generate_command)
    main.add_command(get_command)
    main.add_command(list_command)
    main()
