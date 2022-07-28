package version

import (
	"deco/cmd/root"
	"fmt"
	"log"
	"runtime/debug"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use: "version",
	RunE: func(cmd *cobra.Command, args []string) error {
		info, ok := debug.ReadBuildInfo()
		if !ok {
			return fmt.Errorf("no build info")
		}
		log.Printf("[INFO] version: %s ", info.Main.Version)
		return nil
	},
}

func init() {
	root.RootCmd.AddCommand(versionCmd)
}
