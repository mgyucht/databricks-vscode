package env

import (
	"deco/cmd/root"
	"deco/prompt"
	"deco/testenv"

	"github.com/spf13/cobra"
)

var EnvCmd = &cobra.Command{
	Use:   "env",
	Short: "Utilities for working with environments",
}

var Name string

func GetName() string {
	if Name != "" {
		return Name
	}
	envs := []prompt.Answer{}
	for _, v := range testenv.Available() {
		envs = append(envs, prompt.Answer{
			Value:    v.Name,
			Details:  v.SourceDir,
			Callback: nil,
		})
	}
	_, res, _ := prompt.Choice{
		Key:     "env",
		Label:   "Environment",
		Answers: envs,
	}.Ask(prompt.Results{})
	return res.Value
}

func init() {
	root.RootCmd.AddCommand(EnvCmd)
	EnvCmd.PersistentFlags().StringVarP(&Name, "name", "n", "", "Environment name")
}
