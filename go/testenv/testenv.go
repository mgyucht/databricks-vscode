package testenv

import (
	"context"
	"deco/fileset"
	"deco/folders"
	"deco/terraform"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/Azure/azure-sdk-for-go/sdk/azidentity"
	"github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets"
	"github.com/databricks/terraform-provider-databricks/common"
)

func Available() []string {
	projectRoot, err := folders.FindDirWithLeaf(".git")
	if err != nil {
		log.Printf("[ERROR] no git: %s", err)
		return nil
	}
	prefix := fmt.Sprintf("%s/ops/environments", projectRoot)
	dirs, err := fileset.ReadDir(prefix)
	if err != nil {
		log.Printf("[ERROR] no dir %s", err)
		return nil
	}
	envs := []string{}
	special := map[string]bool{
		"meta":    true,
		"wiki":    true,
		"aws-iam": true,
	}
	for _, v := range dirs {
		if special[v.Name()] {
			continue
		}
		envs = append(envs, v.Name())
	}
	return envs
}

func EnvVars(ctx context.Context, env string) (map[string]string, error) {
	projectRoot, err := folders.FindDirWithLeaf(".git")
	if err != nil {
		return nil, fmt.Errorf("cannot find git root: %w", err)
	}
	wd := fmt.Sprintf("%s/ops/environments/%s", projectRoot, env)
	tf, err := terraform.NewTerraform(wd)
	if err != nil {
		return nil, fmt.Errorf("terraform: %w", err)
	}
	log.Printf("[INFO] Getting terraform state for %s", wd)
	state, err := tf.Show(ctx)
	if err != nil {
		return nil, fmt.Errorf("terraform state: %w", err)
	}
	vaultURI, err := terraform.FindFirstResource(state, "azurerm_key_vault", func(r *terraform.Resource) *string {
		if r.MustStr("name") != fmt.Sprintf("deco-gh-%s", env) {
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
	for pager.More() {
		page, err := pager.NextPage(ctx)
		if err != nil {
			log.Fatal(err)
		}
		for _, secret := range page.Value {
			name := secret.ID.Name()
			if !strings.HasPrefix(name, "DATABRICKS-") {
				continue
			}
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
