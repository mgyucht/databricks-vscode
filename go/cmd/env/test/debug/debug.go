package debug

import (
	"deco/cmd/env/test"
	"deco/ecosystem"
	"deco/prompt"
	"fmt"

	"github.com/spf13/cobra"
)

var debugCmd = &cobra.Command{
	Use:   "debug",
	Short: "Runs a test on environment",
	RunE: func(cmd *cobra.Command, args []string) error {
		_, files, err := test.CheckoutFileset()
		if err != nil {
			return err
		}
		var runner ecosystem.TestRunner
		for _, v := range test.Runners {
			if v.Detect(files) {
				runner = v
			}
		}
		if runner == nil {
			return fmt.Errorf("no supported ecosystem detected")
		}
		if len(args) == 0 {
			args = append(args, prompt.AskString("Test", runner.ListAll(files)))
		}
		return runner.RunOne(cmd.Context(), files, args[0])
	},
}

func init() {
	test.TestCmd.AddCommand(debugCmd)
}
