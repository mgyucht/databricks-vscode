package code

import (
	"deco/cmd/root"

	"github.com/spf13/cobra"
)

var CodeCmd = &cobra.Command{
	Use:   "code",
	Short: "Utilities for working with code generation",
}

func init() {
	root.RootCmd.AddCommand(CodeCmd)
}
