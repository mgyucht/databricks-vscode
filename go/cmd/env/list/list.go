package list

import (
	"deco/cmd/env"
	"deco/testenv"

	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "Listing all environments",
	RunE: func(cmd *cobra.Command, args []string) error {
		for _, v := range testenv.Available() {
			println(v.Name, v.SourceDir)
		}
		return nil
	},
}

func init() {
	env.EnvCmd.AddCommand(listCmd)
}
