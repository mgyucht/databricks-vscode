package shell

import (
	"deco/cmd/env"
	"deco/testenv"
	"fmt"
	"os"
	"syscall"

	"github.com/spf13/cobra"
)

var shellCmd = &cobra.Command{
	Use:   "shell",
	Short: "Launching a shell with the environment",
	RunE: func(cmd *cobra.Command, _ []string) error {
		env := env.GetName()
		vars, err := testenv.EnvVars(cmd.Context(), env)
		if err != nil {
			return err
		}
		environ := os.Environ()
		environ = append(environ, fmt.Sprintf(
			`PS1=\033[1;34m(%s)\033[0m \033[0;32m${PWD/*\//}\033[0m $ `,
			env))
		for k, v := range vars {
			environ = append(environ, fmt.Sprintf("%s=%s", k, v))
		}
		// We point DATABRICKS_CONFIG_FILE to a null file to avoid 
		// conflicts between a pre-existing auth setup (typically in a 
		// .databrickscfg file) and auth injected into the enviorment
		environ = append(environ, "DATABRICKS_CONFIG_FILE=/dev/null")
		return syscall.Exec("/bin/bash", []string{}, environ)
	},
}

func init() {
	env.EnvCmd.AddCommand(shellCmd)
}
