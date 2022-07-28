package export

import (
	"deco/cmd/env"
	"deco/cmd/root"
	"deco/testenv"
	"fmt"

	"github.com/spf13/cobra"
)

var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "Exporting environment configuration for `export $(..)`",
	RunE: func(cmd *cobra.Command, _ []string) error {
		root.NoLogs()
		vars, err := testenv.EnvVars(cmd.Context(), env.GetName())
		if err != nil {
			return err
		}
		for k, v := range vars {
			println(fmt.Sprintf(`%s='%s'`, k, v))
		}
		return nil
	},
}

func init() {
	env.EnvCmd.AddCommand(exportCmd)
}
