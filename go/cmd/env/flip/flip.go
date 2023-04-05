package flip

import (
	"deco/cmd/env"
	"deco/testenv"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"path/filepath"

	"github.com/spf13/cobra"
)

type debugEnv map[string]map[string]string

func loadDebugEnv() (string, debugEnv, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", nil, fmt.Errorf("cannot find user home: %w", err)
	}

	configFile := filepath.Join(home, ".databricks/debug-env.json")

	// Create file if it doesn't exist
	if _, err := os.Stat(configFile); os.IsNotExist(err) {
		file, _ := os.Create(configFile)
		defer file.Close()
		file.WriteString("{}")
	}

	raw, err := os.ReadFile(configFile)
	if err != nil {
		return configFile, nil, fmt.Errorf("cannot load ~/.databricks/debug-env.json: %w", err)
	}
	var conf map[string]map[string]string
	err = json.Unmarshal(raw, &conf)
	if err != nil {
		return configFile, nil, fmt.Errorf("cannot parse ~/.databricks/debug-env.json: %w", err)
	}
	return configFile, conf, nil
}

var flipCmd = &cobra.Command{
	Use:       "flip workspace|account|ucws|ucacct",
	Short:     "Flip environment for ~/.databricks/debug-env.json",
	ValidArgs: []string{"workspace", "account", "ucws", "ucacct"},
	Args:      cobra.ExactValidArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		key := args[0]
		configFile, conf, err := loadDebugEnv()
		if err != nil && !errors.Is(err, os.ErrNotExist) {
			return err
		}
		vars, err := testenv.EnvVars(cmd.Context(), env.GetName())
		if err != nil {
			return err
		}
		conf[key] = vars
		raw, err := json.MarshalIndent(conf, "", "  ")
		if err != nil {
			return err
		}
		return os.WriteFile(configFile, raw, 0o600)
	},
}

func init() {
	env.EnvCmd.AddCommand(flipCmd)
}
