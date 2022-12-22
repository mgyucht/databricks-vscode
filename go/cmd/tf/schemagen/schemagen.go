package schemagen

import (
	"bytes"
	"deco/cmd/tf"
	"fmt"
	"go/format"
	"html/template"
	"os"
	"strings"

	"github.com/spf13/cobra"
)

var schemagenCmd = &cobra.Command{
	Use:   "schemagen RESOURCE",
	Short: "Schema for a terraform resource for migrations",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		tf, err := tf.ShimmedLocal(cmd.Context())
		if err != nil {
			return err
		}
		defer os.RemoveAll(tf.WorkingDir())
		schemas, err := tf.ProvidersSchema(cmd.Context())
		if err != nil {
			return err
		}
		p := schemas.Schemas["registry.terraform.io/databricks/databricks"]
		resourceSchema, ok := p.ResourceSchemas[args[0]]
		if !ok {
			return fmt.Errorf("no %s resource", args[0])
		}
		buf := bytes.NewBuffer([]byte{})
		err = tmpl.Execute(buf, resourceSchema)
		if err != nil {
			return err
		}
		pretty, err := format.Source(buf.Bytes())
		if err != nil {
			return err
		}
		cmd.OutOrStdout().Write(pretty)
		return nil
	},
}

func init() {
	tf.TfCmd.AddCommand(schemagenCmd)
}

var tmpl = template.Must(template.New("_").Funcs(template.FuncMap{"title": strings.Title}).Parse(`
import (
	"github.com/hashicorp/go-cty/cty"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

// StateUpgraders: []schema.StateUpgrader{
// 	{
// 		Version: {{.Version}},
// 		Type:    schemaV{{.Version}}(),
// 		Upgrade: migrateV{{.Version}},
// 	},
// },

func migrateV{{.Version}}(ctx context.Context, rawState map[string]any, meta any) (map[string]any, error) {
	newState := map[string]any{}
	for k, v := range rawState {
		switch k {
		case "removed_key1", "removed_key2":
			log.Printf("[INFO] Migrated from schema v{{.Version}} and removed key %s", k)
			continue
		case "changed_key":
			newState["changed_key"] = modified(v)
			log.Printf("[INFO] State of changed_key is migrated from schema v{{.Version}}")
		default:
			newState[k] = v
		}
	}
	return newState, nil
}

func schemaV{{.Version}}() cty.Type {
	return (&schema.Resource{
		Schema: map[string]*schema.Schema{
			{{- template "block" .Block}}
		},
	}).CoreConfigSchema().ImpliedType()
}

{{define "block" -}}
	{{- range $k, $v := .Attributes -}}
	"{{ $k }}": {
		Type: schema.Type{{ $v.AttributeType.FriendlyName | title }},{{if $v.Required}}
		Required: {{$v.Required}},{{end}}{{if $v.Optional}}
		Optional: {{$v.Optional}},{{end}}{{if $v.Computed}}
		Computed: {{$v.Computed}},{{end}}{{if $v.Sensitive}}
		Sensitive: {{$v.Sensitive}},{{end}}
	},
	{{ end }}{{- range $k, $v := .NestedBlocks }}
	"{{ $k }}": {
		Type: schema.TypeList,
		Elem: &schema.Resource{
			Schema: map[string]*schema.Schema{
				{{template "block" .Block}}
			},
		},
	},
	{{- end }}
{{- end -}}
`))
