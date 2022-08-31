package cov

import (
	"deco/cmd/tf"
	"deco/folders"
	"deco/terraform"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

var tfcovCmd = &cobra.Command{
	Use:   "cov",
	Short: "Coverage for Terraform Provider",
	RunE: func(cmd *cobra.Command, args []string) error {
		projectRoot, err := folders.FindDirWithLeaf(".git")
		if err != nil {
			return err
		}
		tmpDir, err := os.MkdirTemp("", "tf-provider-*")
		if err != nil {
			return err
		}
		defer os.RemoveAll(tmpDir)
		rcFile := filepath.Join(tmpDir, ".terraformrc")
		rc, err := os.OpenFile(rcFile, os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0700)
		if err != nil {
			return err
		}
		tfProviderCheckout, err := filepath.Abs(filepath.Join(
			projectRoot, "ext/terraform-provider-databricks"))
		if err != nil {
			return err
		}
		_, err = rc.WriteString(fmt.Sprintf(`provider_installation {
		dev_overrides {
		   "databricks/databricks" = "%s"
		}
		direct {}
		}`, tfProviderCheckout))
		if err != nil {
			return err
		}
		err = rc.Close()
		if err != nil {
			return err
		}
		shim, err := os.OpenFile(filepath.Join(tmpDir, "providers.tf"),
			os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0700)
		if err != nil {
			return err
		}
		_, err = shim.WriteString(`terraform {
			required_providers {
				databricks = {
					source = "databricks/databricks"
				}
			}
		}`)
		if err != nil {
			return err
		}
		err = shim.Close()
		if err != nil {
			return err
		}
		tf, err := terraform.NewTerraform(tmpDir)
		if err != nil {
			return err
		}
		err = tf.SetEnv(map[string]string{
			// https://www.terraform.io/cli/config/config-file
			"TF_CLI_CONFIG_FILE": rcFile,
		})
		if err != nil {
			return err
		}
		err = tf.Init(cmd.Context())
		if err != nil {
			return err
		}
		schemas, err := tf.ProvidersSchema(cmd.Context())
		if err != nil {
			return err
		}
		return prepare(schemas.Schemas["registry.terraform.io/databricks/databricks"])
	},
}

func init() {
	tf.TfCmd.AddCommand(tfcovCmd)
}
