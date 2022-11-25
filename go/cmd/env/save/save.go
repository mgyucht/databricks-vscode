package save

import (
	"deco/cmd/env"
	"deco/testenv"
	"fmt"
	"log"
	"os"
	"path/filepath"

	"github.com/databricks/databricks-sdk-go/config"
	"github.com/spf13/cobra"
	"gopkg.in/ini.v1"
)

var profileCmd = &cobra.Command{
	Use:   "save",
	Short: "Saves environment as ~/.databrickscfg profile",
	RunE: func(cmd *cobra.Command, _ []string) error {
		vars, err := testenv.EnvVars(cmd.Context(), env.GetName())
		if err != nil {
			return err
		}
		homedir, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("cannot find homedir: %w", err)
		}
		configFile := filepath.Join(homedir, ".databrickscfg")
		iniFile, err := ini.Load(configFile)
		if err != nil {
			return fmt.Errorf("cannot parse config file: %w", err)
		}
		section, err := iniFile.NewSection(env.GetName())
		if err != nil {
			return fmt.Errorf("new section: %w", err)
		}
		for _, a := range config.ConfigAttributes {
			for _, ev := range a.EnvVars {
				v, ok := vars[ev]
				if !ok {
					continue
				}
				_, err = section.NewKey(a.Name, v)
				if err != nil {
					return fmt.Errorf("new key %s: %w", a.Name, err)
				}
			}
		}
		// ignoring err because we've read the file already
		orig, _ := os.ReadFile(configFile)
		log.Printf("[INFO] Backing up in %s.bak", configFile)
		err = os.WriteFile(configFile+".bak", orig, 0o600)
		if err != nil {
			return fmt.Errorf("backup: %w", err)
		}
		log.Printf("[INFO] Overriding %s", configFile)
		return iniFile.SaveTo(configFile)
	},
}

func init() {
	env.EnvCmd.AddCommand(profileCmd)
}
