package api

import (
	"deco/cmd/root"
	"deco/testenv"
	"fmt"

	"github.com/TylerBrock/colorjson"
	"github.com/spf13/cobra"
)

var apiCmd = &cobra.Command{
	Use:   "api",
	Short: "Makes a call to Databricks REST API in environment",
	Args:  cobra.ExactArgs(2),
	RunE: func(cmd *cobra.Command, args []string) error {
		client, err := testenv.NewClientFor(cmd.Context(), args[0])
		if err != nil {
			return err
		}
		var response any
		path := args[1]
		err = client.Get(cmd.Context(), path, nil, &response)
		if err != nil {
			return fmt.Errorf("GET %s: %w", path, err)
		}
		twoSpaceJson := colorjson.NewFormatter()
		twoSpaceJson.Indent = 2
		raw, err := twoSpaceJson.Marshal(response)
		if err != nil {
			return fmt.Errorf("json marshal: %w", err)
		}
		println(string(raw))
		return nil
	},
}

var Env string

func init() {
	root.RootCmd.AddCommand(apiCmd)
}
