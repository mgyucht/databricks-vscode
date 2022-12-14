package test

import (
	"deco/cmd/env"
	"deco/ecosystem"
	"deco/ecosystem/golang"
	"deco/fileset"
	"deco/folders"
	"deco/prompt"
	"fmt"
	"log"
	"os"

	"github.com/spf13/cobra"
)

var Runners = []ecosystem.TestRunner{
	golang.GoTestRunner{},
}

// Returns the repository root of the working directory, iff
// it is different from the eng-dev-ecosystem repository.
func findWorkingDirectoryGitRoot() (string, error) {
	engDevEcosystemRoot, err := folders.FindEngDevEcosystemRoot()
	if err != nil {
		return "", err
	}
	wd, err := os.Getwd()
	if err != nil {
		return "", err
	}
	wdRoot, err := folders.FindDirWithLeaf(wd, ".git")
	if err != nil {
		return "", err
	}
	if wdRoot == engDevEcosystemRoot {
		return "", fmt.Errorf("working directory inside 'eng-dev-ecosystem'")
	}
	return wdRoot, nil
}

func CheckoutFileset() (string, fileset.FileSet, error) {
	engDevEcosystemRoot, err := folders.FindEngDevEcosystemRoot()
	if err != nil {
		return "", nil, err
	}

	var checkout string

	// If the repo is NOT specified already, we first try to see
	// if we can determine it by looking at the working directory.
	if repo == "" {
		gitRoot, err := findWorkingDirectoryGitRoot()
		if err != nil {
			log.Printf("[DEBUG] Unable to infer repo from working directory: %s", err)
		} else {
			checkout = gitRoot
		}
	}

	// Prompt the user to specify a repo if not specified.
	if checkout == "" && repo == "" {
		repos := []string{}
		dirs, err := fileset.ReadDir(fmt.Sprintf("%s/ext", engDevEcosystemRoot))
		if err != nil {
			return "", nil, err
		}
		for _, v := range dirs {
			repos = append(repos, v.Name())
		}
		repo = prompt.AskString("Repo", repos)
	}

	if checkout == "" {
		checkout = fmt.Sprintf("%s/ext/%s", engDevEcosystemRoot, repo)
	}

	log.Printf("[INFO] Locating tests in %s", checkout)
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
