package tf

import (
	"context"
	"deco/cmd/root"
	"deco/folders"
	"deco/terraform"
	"fmt"
	"os"
	"path/filepath"

	"github.com/hashicorp/terraform-exec/tfexec"
	"github.com/spf13/cobra"
)

var TfCmd = &cobra.Command{
	Use:   "tf",
	Short: "terraform related commands",
}

func init() {
	root.RootCmd.AddCommand(TfCmd)
}

func ShimmedLocal(ctx context.Context) (*tfexec.Terraform, error) {
	wd, err := os.Getwd()
	if err != nil {
		return nil, fmt.Errorf("cannot find $PWD: %s", err)
	}
	projectRoot, err := folders.FindDirWithLeaf(wd, ".git")
	if err != nil {
		return nil, err
	}
	tmpDir, err := os.MkdirTemp("/tmp", "tf-provider-*")
	if err != nil {
		return nil, err
	}
	rcFile := filepath.Join(tmpDir, ".terraformrc")
	rc, err := os.OpenFile(rcFile, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0700)
	if err != nil {
		return nil, err
	}
	tfProviderCheckout, err := filepath.Abs(filepath.Join(
		projectRoot, "ext/terraform-provider-databricks"))
	if err != nil {
		return nil, err
	}
	_, err = rc.WriteString(fmt.Sprintf(`provider_installation {
	dev_overrides {
		"databricks/databricks" = "%s"
	}
	direct {}
	}`, tfProviderCheckout))
	if err != nil {
		return nil, err
	}
	err = rc.Close()
	if err != nil {
		return nil, err
	}
	shim, err := os.OpenFile(filepath.Join(tmpDir, "providers.tf"),
		os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0700)
	if err != nil {
		return nil, err
	}
	_, err = shim.WriteString(`terraform {
		required_providers {
			databricks = {
				source = "databricks/databricks"
			}
		}
	}`)
	if err != nil {
		return nil, err
	}
	err = shim.Close()
	if err != nil {
		return nil, err
	}
	tf, err := terraform.NewTerraform(tmpDir)
	if err != nil {
		return nil, fmt.Errorf("new tf: %w", err)
	}
	err = tf.SetEnv(map[string]string{
		// https://www.terraform.io/cli/config/config-file
		"TF_CLI_CONFIG_FILE": rcFile,
	})
	if err != nil {
		return nil, fmt.Errorf("tf env: %w", err)
	}
	err = tf.Init(ctx)
	if err != nil {
		return nil, fmt.Errorf("tf init: %w", err)
	}
	return tf, nil
}
