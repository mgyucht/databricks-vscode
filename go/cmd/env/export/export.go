package export

import (
	"deco/cmd/env"
	"deco/cmd/root"
	"deco/testenv"
	"fmt"

	"github.com/spf13/cobra"
)

// If true, wrap values in single quotes.
// This must be done when using the output of this command as input to your shell or `export`.
// This must NOT be done when appending the output to $GITHUB_ENV in GitHub Actions.
var quoteValues bool = true

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
			if quoteValues {
				v = fmt.Sprintf(`'%s'`, v)
			}
			fmt.Printf("%s=%s\n", k, v)
		}
		return nil
	},
}

func init() {
	exportCmd.Flags().BoolVar(&quoteValues, "quote-values", true, "Include single quotes around values")
	env.EnvCmd.AddCommand(exportCmd)
}
