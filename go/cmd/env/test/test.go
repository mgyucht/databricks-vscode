package test

import (
	"deco/cmd/env"
	"deco/ecosystem"
	"deco/ecosystem/golang"
	"deco/fileset"
	"deco/folders"
	"deco/prompt"
	"fmt"

	"github.com/spf13/cobra"
)

var Runners = []ecosystem.TestRunner{
	golang.GoTestRunner{},
}

func CheckoutFileset() (string, fileset.FileSet, error) {
	projectRoot, err := folders.FindEngDevEcosystemRoot()
	if err != nil {
		return "", nil, err
	}
	if repo == "" {
		repos := []string{}
		dirs, err := fileset.ReadDir(fmt.Sprintf("%s/ext", projectRoot))
		if err != nil {
			return "", nil, err
		}
		for _, v := range dirs {
			repos = append(repos, v.Name())
		}
		repo = prompt.AskString("Repo", repos)
	}
	// TODO: perhaps with deco CLI we can make it into other repos as well
	checkout := fmt.Sprintf("%s/ext/%s", projectRoot, repo)
	files, err := fileset.RecursiveChildren(checkout)
	if err != nil {
		return "", nil, err
	}
	return repo, files, nil
}

var TestCmd = &cobra.Command{
	Use:   "test",
	Short: "Runs tests in the environment",
}

var repo string

func init() {
	env.EnvCmd.AddCommand(TestCmd)
	TestCmd.PersistentFlags().StringVarP(&repo, "repo", "r", "", "Repo name")
}
