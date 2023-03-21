package clonerepos

import (
	"context"
	"deco/cmd/gh"
	"deco/folders"
	"deco/prompt"
	"fmt"
	"log"
	"os"
	"os/exec"
	"path/filepath"
	"strings"

	"github.com/spf13/cobra"
)

var checkoutRepos = &cobra.Command{
	Use:   "clone-repos",
	Short: "Clones & symlinks Deco Team Repos to ext/",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := cmd.Context()
		client := gh.Client(ctx)
		dir, err := getCloneDir()
		repos, _, err := client.Teams.ListTeamReposBySlug(ctx, "databricks", "eng-dev-ecosystem", nil)
		if err != nil {
			return err
		}
		projectRoot, err := folders.FindEngDevEcosystemRoot()
		if err != nil {
			return err
		}
		err = checkCloneDir()
		if err != nil {
			return err
		}
		for _, r := range repos {
			repoPath := filepath.Join(dir, *r.Name)

			// Clone the repo if it does not exist at repoPath
			cloneUrl := r.GetSSHURL()
			cloneRepoIfNotExists(ctx, cloneUrl, repoPath)

			// Setup symlinks if they don't exist
			symlinkPath := filepath.Join(projectRoot, "ext", *r.Name)
			createSymlinkIfNotExists(repoPath, symlinkPath)
		}
		return nil
	},
}

func cloneRepoIfNotExists(ctx context.Context, cloneUrl, repoPath string) error {
	_, err := os.Stat(repoPath)
	if os.IsNotExist(err) {
		log.Printf("[INFO] Cloning Repo %s to %s", cloneUrl, repoPath)
		res, err := exec.CommandContext(ctx, "git", "clone", cloneUrl, repoPath).Output()
		if err != nil {
			return err
		}
		log.Printf("[DEBUG] clone result: %s", res)
	} else if err == nil { // the path exists
		log.Printf("[INFO] Skipping cloning repo to %s (path already exists)", repoPath)
	} else {
		return err
	}
	return nil
}

func createSymlinkIfNotExists(repoPath, symlinkPath string) error {
	err := os.Symlink(repoPath, symlinkPath)
	if os.IsExist(err) {
		log.Printf("[INFO] Skipped symlink %s to %s (%s already exists)", symlinkPath, repoPath, symlinkPath)
	} else if err == nil {
		log.Printf("[INFO] Symlinked %s to %s", repoPath, symlinkPath)
	} else {
		return err
	}
	return nil
}

func checkCloneDir() error {
	res, err := os.Stat(cloneDir)
	if err != nil {
		return err
	}
	if !res.IsDir() {
		return fmt.Errorf("path %s is not a directory", cloneDir)
	}
	return nil
}

var cloneDir string

func getCloneDir() (string, error) {
	if cloneDir != "" {
		return cloneDir, nil
	}
	t := prompt.Text{
		Label:    "Clone Directory",
		Default:  nil,
		Callback: nil,
	}
	var r prompt.Results
	_, answer, err := t.Ask(r)
	if err != nil {
		panic("failed reading clone directory")
	}
	cloneDir = answer.String()
	if cloneDir == "~" {
		cloneDir, err = os.UserHomeDir()
		if err != nil {
			return "", err
		}
	} else if strings.HasPrefix(cloneDir, "~/") {
		var homeDir string
		homeDir, err = os.UserHomeDir()
		if err != nil {
			return "", err
		}
		cloneDir = filepath.Join(homeDir, cloneDir[2:])
	}
	return cloneDir, nil
}

func init() {
	gh.GhCmd.AddCommand(checkoutRepos)
	defaultCloneDir, _ := os.UserHomeDir()
	checkoutRepos.Flags().StringVar(&cloneDir, "dir", defaultCloneDir, "The directory where repos should be cloned, must already exist")
}
