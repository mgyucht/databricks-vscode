package api

import (
	"deco/cmd/env"
	"deco/testenv"
	"fmt"

	"github.com/TylerBrock/colorjson"
	"github.com/databricks/databricks-sdk-go/client"
	"github.com/spf13/cobra"
)

var apiCmd = &cobra.Command{
	Use:   "api <path>",
	Short: "Makes a call to Databricks REST API in environment",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		cfg, err := testenv.NewConfigFor(cmd.Context(), env.GetName())
		if err != nil {
			return err
		}
		var response any
		path := args[0]

		apiClient, err := client.New(cfg)
		if err != nil {
			return err
		}
		err = apiClient.Do(cmd.Context(), "GET", path, nil, &response)
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

func init() {
	env.EnvCmd.AddCommand(apiCmd)
}
