package cov

import (
	"deco/cmd/tf"
	"os"

	"github.com/spf13/cobra"
)

var tfcovCmd = &cobra.Command{
	Use:   "cov",
	Short: "Coverage for Terraform Provider",
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
		return prepare(schemas.Schemas["registry.terraform.io/databricks/databricks"])
	},
}

func init() {
	tf.TfCmd.AddCommand(tfcovCmd)
}
