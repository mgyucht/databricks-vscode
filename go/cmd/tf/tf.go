package tf

import (
	"deco/cmd/root"

	"github.com/spf13/cobra"
)

var TfCmd = &cobra.Command{
	Use:   "tf",
	Short: "terraform related commands",
}

func init() {
	root.RootCmd.AddCommand(TfCmd)
}
