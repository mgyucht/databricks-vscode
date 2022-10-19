package slack

import (
	"deco/cmd/root"

	"github.com/spf13/cobra"
)

var SlackCmd = &cobra.Command{
	Use:   "slack",
	Short: "Utilities for working with Slack",
}

func init() {
	root.RootCmd.AddCommand(SlackCmd)
}
