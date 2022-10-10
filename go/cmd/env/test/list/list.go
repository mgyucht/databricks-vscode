package list

import (
	"deco/cmd/env/test"
	"deco/ecosystem"
	"fmt"

	"github.com/spf13/cobra"
)

var listCmd = &cobra.Command{
	Use:   "list",
	Short: "lists acceptance tests in repo",
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
		acceptanceTests := runner.ListAll(files)
		fmt.Println("List of acceptance tests: ")
		for _, v := range acceptanceTests {
			fmt.Println(v)
		}
		return nil
	},
}

func init() {
	test.TestCmd.AddCommand(listCmd)
}
