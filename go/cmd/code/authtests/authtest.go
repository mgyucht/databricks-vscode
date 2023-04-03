package authtests

import (
	"bufio"
	"deco/cmd/code"
	"deco/fileset"
	"deco/folders"
	"encoding/json"
	"fmt"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"text/template"

	codegen "github.com/databricks/databricks-sdk-go/openapi/code"
	"github.com/spf13/cobra"
)

type configFixture struct {
	Name              string            `json:"name"`
	Host              string            `json:"host,omitempty"`
	Token             string            `json:"token,omitempty"`
	Username          string            `json:"username,omitempty"`
	Password          string            `json:"password,omitempty"`
	ConfigFile        string            `json:"config_file,omitempty"`
	Profile           string            `json:"profile,omitempty"`
	AzureClientID     string            `json:"azure_client_id,omitempty"`
	AzureClientSecret string            `json:"azure_client_secret,omitempty"`
	AzureTenantID     string            `json:"azure_tenant_id,omitempty"`
	AzureResourceID   string            `json:"azure_workspace_resource_id,omitempty"`
	AuthType          string            `json:"auth_type,omitempty"`
	Env               map[string]string `json:"env,omitempty"`
	AssertError       string            `json:"assertError,omitempty"`
	AssertAuth        string            `json:"assertAuth,omitempty"`
	AssertHost        string            `json:"assertHost,omitempty"`
	AssertAzure       bool              `json:"assertAzure,omitempty"`
}

type pair struct {
	Key, Value string
}

func (cf configFixture) SnakeName() string {
	named := &codegen.Named{
		Name: cf.Name,
	}
	return named.SnakeName()
}

func (cf configFixture) Fields() []pair {
	fields := []pair{}
	if cf.Host != "" {
		fields = append(fields, pair{"host", cf.Host})
	}
	if cf.Token != "" {
		fields = append(fields, pair{"token", cf.Token})
	}
	if cf.Username != "" {
		fields = append(fields, pair{"username", cf.Username})
	}
	if cf.Password != "" {
		fields = append(fields, pair{"password", cf.Password})
	}
	if cf.ConfigFile != "" {
		fields = append(fields, pair{"config_file", cf.ConfigFile})
	}
	if cf.Profile != "" {
		fields = append(fields, pair{"profile", cf.Profile})
	}
	if cf.AzureClientID != "" {
		fields = append(fields, pair{"azure_client_id", cf.AzureClientID})
	}
	if cf.AzureClientSecret != "" {
		fields = append(fields, pair{"azure_client_secret", cf.AzureClientSecret})
	}
	if cf.AzureTenantID != "" {
		fields = append(fields, pair{"azure_tenant_id", cf.AzureTenantID})
	}
	if cf.AzureResourceID != "" {
		fields = append(fields, pair{"azure_workspace_resource_id", cf.AzureResourceID})
	}
	if cf.AuthType != "" {
		fields = append(fields, pair{"auth_type", cf.AuthType})
	}
	return fields
}

var authPermsCmd = &cobra.Command{
	Use: "auth-tests",
	RunE: func(cmd *cobra.Command, args []string) error {
		engDevEcosystemRoot, err := folders.FindEngDevEcosystemRoot()
		if err != nil {
			return err
		}
		goSdkPath, err := filepath.EvalSymlinks(filepath.Join(engDevEcosystemRoot, "ext/databricks-sdk-go"))
		if err != nil {
			return err
		}
		runTestsCmd := exec.Command("go", "test", "github.com/databricks/databricks-sdk-go/config",
			"-run", "^TestConfig_")
		runTestsCmd.Dir = goSdkPath
		runTestsCmd.Env = append(os.Environ(), "DATABRICKS_AUTH_FIXTURES_DUMP=/tmp/auth-fixtures.json")
		err = runTestsCmd.Run()
		if err != nil {
			return err
		}
		// /tmp/auth-fixtures.json
		fixtureFile, err := os.Open("/tmp/auth-fixtures.json")
		if err != nil {
			return err
		}
		defer fixtureFile.Close()
		fixtures := []configFixture{}
		scanner := bufio.NewScanner(fixtureFile)
		for scanner.Scan() {
			line := scanner.Text()
			var fixture configFixture
			err = json.Unmarshal([]byte(line), &fixture)
			if err != nil {
				return err
			}
			for k, v := range fixture.Env {
				v = strings.ReplaceAll(v, filepath.Join(goSdkPath, "config")+"/", "")
				fixture.Env[k] = v
			}
			fixture.AssertError = strings.ReplaceAll(fixture.AssertError, "\n", "\\n")
			fixtures = append(fixtures, fixture)
		}
		gitRoot, err := folders.FindWorkingDirectoryGitRoot()
		if err != nil {
			return err
		}
		files, err := fileset.RecursiveChildren(gitRoot)
		if err != nil {
			return err
		}
		testTmpl := files.FirstMatch(`.*.tmpl`, `These are auto-generated tests for Unified Authentication`)
		if testTmpl == nil {
			return fmt.Errorf("cannot file a template for auth tests")
		}
		t, err := template.ParseFiles(testTmpl.Absolute)
		if err != nil {
			return err
		}
		toBeOverwritten := strings.TrimSuffix(testTmpl.Absolute, ".tmpl")
		targetFile, err := os.Create(toBeOverwritten)
		if err != nil {
			return err
		}
		defer targetFile.Close()
		return t.Execute(targetFile, fixtures)
	},
}

func init() {
	code.CodeCmd.AddCommand(authPermsCmd)
}
