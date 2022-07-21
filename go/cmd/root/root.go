package root

import (
	"context"
	"log"
	"os"
	"strings"

	"github.com/spf13/cobra"
)

// RootCmd represents the base command when called without any subcommands
var RootCmd = &cobra.Command{
	Use:   "deco",
	Short: "Eng Dev Ecosystem Internal Toolkit",
	PersistentPreRun: func(_ *cobra.Command, _ []string) {
		if Verbose {
			logLevel = append(logLevel, "[DEBUG]")
		}
		log.SetOutput(&logLevel)
	},
}

// TODO: replace with zerolog
type levelWriter []string

var logLevel = levelWriter{"[INFO]", "[ERROR]", "[WARN]"}

// Verbose means additional debug information, like API logs
var Verbose bool

func (lw *levelWriter) Write(p []byte) (n int, err error) {
	a := string(p)
	for _, l := range *lw {
		if strings.Contains(a, l) {
			return os.Stdout.Write(p)
		}
	}
	return
}

func Execute() {
	// TODO: deferred panic recovery
	ctx := context.Background()
	err := RootCmd.ExecuteContext(ctx)
	if err != nil {
		os.Exit(1)
	}
}

func init() {
	// flags available for every child command
	RootCmd.PersistentFlags().BoolVarP(&Verbose, "verbose", "v", false, "print debug logs")
}
