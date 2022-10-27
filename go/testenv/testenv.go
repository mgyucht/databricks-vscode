package testenv

import (
	"context"
	"deco/fileset"
	"deco/folders"
	"deco/terraform/tf"
	"encoding/base64"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets"
	"github.com/databricks/databricks-sdk-go/databricks"
)

type Env struct {
	Name      string
	SourceDir string
}

func Available() []Env {
	projectRoot, err := folders.FindEngDevEcosystemRoot()
	if err != nil {
		log.Printf("[ERROR] no git: %s", err)
		return nil
	}
	prefix := fmt.Sprintf("%s/ops/environments", projectRoot)
	dir, err := fileset.RecursiveChildren(prefix)
	if err != nil {
		log.Printf("[ERROR] no dir %s", err)
		return nil
	}
	envs := []Env{}
	special := map[string]bool{
		"meta":    true,
		"wiki":    true,
		"aws-iam": true,
	}
	for _, file := range dir {
		if !file.Ext(".tf") {
			continue
		}
		tfFile, err := tf.NewFromFile(file)
		if err != nil {
			continue
		}
		tfFile.ForEach(func(block *tf.Block) error {
			sourceAttr := block.MustStrAttr("source")
			if !strings.HasSuffix(sourceAttr, "/github-secrets") {
				return nil
			}
			name := block.MustStrAttr("environment")
			if special[name] {
				return nil
			}
			envs = append(envs, Env{
				Name:      block.MustStrAttr("environment"),
				SourceDir: tfFile.File.Dir(),
			})
			return nil
		}, "module")
	}
	return envs
}

func getEnv(envName string) (Env, error) {
	for _, currentEnv := range Available() {
		if currentEnv.Name == envName {
			return currentEnv, nil
		}
	}
	return Env{}, fmt.Errorf("no such environment found: %s", envName)
}

func filterEnv(in map[string]string) (map[string]string, error) {
	out := map[string]string{}
	for k, v := range in {
		if k == "github_token" {
			// this is an internal token for github actions.
			// skipping it to avoid potential confusion.
			// perhaps it might be useful in some cases.
			continue
		}
		if k == "GOOGLE_CREDENTIALS" {
			googleCreds, err := base64.StdEncoding.DecodeString(v)
			if err != nil {
				return nil, fmt.Errorf("cannot decode google creds: %w", err)
			}
			v = strings.ReplaceAll(string(googleCreds), "\n", "")
		}
		out[k] = v
	}
	return out, nil
}

func EnvVars(ctx context.Context, envName string) (map[string]string, error) {
	// alternatively retrieve secrets from github actions context env var
	githubSecretsJson := os.Getenv("GITHUB_SECRETS_JSON")
	if githubSecretsJson != "" {
		var allSecrets map[string]string
		err := json.Unmarshal([]byte(githubSecretsJson), &allSecrets)
		if err != nil {
			return nil, fmt.Errorf("cannot parse all github secrets: %w", err)
		}
		return filterEnv(allSecrets)
	}
	env, err := getEnv(envName)
	if err != nil {
		return nil, err
	}

	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return nil, fmt.Errorf("azure default auth: %w", err)
	}

	vaultURI := fmt.Sprintf("https://deco-gh-%s.vault.azure.net/", env.Name)
	log.Printf("[INFO] Listing secrets from %s", vaultURI)
	vault := azsecrets.NewClient(vaultURI, credential, nil)
	pager := vault.NewListSecretsPager(nil)
	vars := map[string]string{}
	// implicit CLOUD_ENV var
	split := strings.Split(env.Name, "-")
	if len(split) > 1 {
		vars["CLOUD_ENV"] = split[0]
	}
	for pager.More() {
		page, err := pager.NextPage(ctx)
		if err != nil {
			log.Fatal(err)
		}
		for _, secret := range page.Value {
			name := secret.ID.Name()
			sv, err := vault.GetSecret(ctx, name, secret.ID.Version(), nil)
			if err != nil {
				return nil, fmt.Errorf("get secret %s: %w", name, err)
			}
			vars[strings.ReplaceAll(name, "-", "_")] = *sv.Value
		}
	}
	return filterEnv(vars)
}

// TODO: HAS ENVIRONMENT SIDE EFFECTS! Will be fixed with Go SDK
func NewConfigFor(ctx context.Context, env string) (*databricks.Config, error) {
	vars, err := EnvVars(ctx, env)
	if err != nil {
		return nil, fmt.Errorf("env vars: %w", err)
	}
	// TODO: THIS IS UGLY AND HAS TO BE REWRITTEN LATER
	for k, v := range vars {
		os.Setenv(k, v)
	}
	log.Printf("[INFO] Creating *databricks.Config for %s env", env)

	cfg := &databricks.Config{}
	return cfg, cfg.EnsureResolved()
}
