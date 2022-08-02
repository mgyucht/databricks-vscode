package testenv

import (
	"context"
	"deco/fileset"
	"deco/folders"
	"deco/terraform"
	"deco/terraform/tf"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets"
	"github.com/databricks/terraform-provider-databricks/common"
)

type Env struct {
	Name      string
	SourceDir string
}

func Available() []Env {
	projectRoot, err := folders.FindDirWithLeaf(".git")
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

func EnvVars(ctx context.Context, envName string) (map[string]string, error) {
	env, err := getEnv(envName)
	if err != nil {
		return nil, err
	}
	tf, err := terraform.NewTerraform(env.SourceDir)
	if err != nil {
		return nil, fmt.Errorf("in directory (%s) terraform: %w", env.SourceDir, err)
	}
	log.Printf("[INFO] Getting terraform state for %s", env.SourceDir)
	state, err := tf.Show(ctx)
	if err != nil {
		return nil, fmt.Errorf("in directory (%s) terraform state: %w", env.SourceDir, err)
	}
	vaultURI, err := terraform.FindFirstResource(state, "azurerm_key_vault", func(r *terraform.Resource) *string {
		if r.MustStr("name") != fmt.Sprintf("deco-gh-%s", env.Name) {
			return nil
		}
		uri := r.MustStr("vault_uri")
		return &uri
	})
	if err != nil {
		return nil, fmt.Errorf("no vault found: %w", err)
	}
	credential, err := azidentity.NewDefaultAzureCredential(nil)
	if err != nil {
		return nil, fmt.Errorf("azure default auth: %w", err)
	}
	log.Printf("[INFO] Listing secrets from %s", *vaultURI)
	vault := azsecrets.NewClient(*vaultURI, credential, nil)
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
	return vars, nil
}

// TODO: HAS ENVIRONMENT SIDE EFFECTS! Will be fixed with Go SDK
func NewClientFor(ctx context.Context, env string) (*common.DatabricksClient, error) {
	vars, err := EnvVars(ctx, env)
	if err != nil {
		return nil, fmt.Errorf("env vars: %w", err)
	}
	// TODO: THIS IS UGLY AND HAS TO BE REWRITTEN LATER
	for k, v := range vars {
		os.Setenv(k, v)
	}
	log.Printf("[INFO] Configuring DatabricksClient for %s env", env)
	return common.NewClientFromEnvironment(), nil
}
