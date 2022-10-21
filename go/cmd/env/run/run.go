package shell

import (
	"deco/cmd/env"
	"deco/testenv"
	"fmt"
	"os"
	"os/exec"
	"syscall"

	"github.com/spf13/cobra"
)

var runCmd = &cobra.Command{
	Use:   "run",
	Short: "Run a command in the environment",
	RunE: func(cmd *cobra.Command, argv []string) error {
		env := env.GetName()
		vars, err := testenv.EnvVars(cmd.Context(), env)
		if err != nil {
			return err
		}
		environ := os.Environ()
		for k, v := range vars {
			environ = append(environ, fmt.Sprintf("%s=%s", k, v))
		}
		// We point DATABRICKS_CONFIG_FILE to a null file to avoid
		// conflicts between a pre-existing auth setup (typically in a
		// .databrickscfg file) and auth injected into the environment.
		environ = append(environ, "DATABRICKS_CONFIG_FILE=/dev/null")
		argv0, err := exec.LookPath(argv[0])
		if err != nil {
			return err
		}
		return syscall.Exec(argv0, argv, environ)
	},
}

func init() {
	env.EnvCmd.AddCommand(runCmd)
}
