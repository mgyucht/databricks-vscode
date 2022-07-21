package env

import (
	"deco/cmd/root"

	"github.com/spf13/cobra"
)

var EnvCmd = &cobra.Command{
	Use:   "env",
	Short: "Utilities for working with environments",
}

var Name string

func init() {
	root.RootCmd.AddCommand(EnvCmd)
	EnvCmd.PersistentFlags().StringVarP(&Name, "name", "n", "", "Environment name")
}
