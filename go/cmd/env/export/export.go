package export

import (
	"deco/cmd/env"
	"deco/cmd/root"
	"deco/testenv"
	"fmt"

	"github.com/spf13/cobra"
	"golang.org/x/exp/slices"
)

// If true, wrap values in single quotes.
// This must be done when using the output of this command as input to your shell or `export`.
// This must NOT be done when appending the output to $GITHUB_ENV in GitHub Actions.
var quoteValues bool = true

// if true, prints data for ~/.databricks/debug-env.json
var asJson bool = true

type kv struct{ k, v string }

var exportCmd = &cobra.Command{
	Use:   "export",
	Short: "Exporting environment configuration for `export $(..)`",
	RunE: func(cmd *cobra.Command, _ []string) error {
		root.NoLogs()
		vars, err := testenv.EnvVars(cmd.Context(), env.GetName())
		if err != nil {
			return err
		}
		var kvs []kv
		for k, v := range vars {
			kvs = append(kvs, kv{k, v})
		}
		slices.SortFunc(kvs, func(a, b kv) bool {
			return a.k < b.k
		})
		if asJson {
			fmt.Printf("{\n")
		}
		for _, x := range kvs {
			if asJson {
				fmt.Printf("        \"%s\": \"%s\",\n", x.k, x.v)
				continue
			}
			if quoteValues {
				x.v = fmt.Sprintf(`'%s'`, x.v)
			}
			fmt.Printf("%s=%s\n", x.k, x.v)
		}
		if asJson {
			fmt.Printf("}\n")
		}
		return nil
	},
}

func init() {
	exportCmd.Flags().BoolVar(&quoteValues, "quote-values", false, "Include single quotes around values")
	exportCmd.Flags().BoolVar(&asJson, "as-json", true, "Print as json profile for ~/.databricks/debug-env.json")
	env.EnvCmd.AddCommand(exportCmd)
}
