package gh

import (
	"context"
	"deco/cmd/root"
	"fmt"
	"io"
	"os"
	"strings"

	"github.com/google/go-github/v45/github"
	"github.com/spf13/cobra"
	"golang.org/x/oauth2"
	"gopkg.in/yaml.v3"
)

var GhCmd = &cobra.Command{
	Use:   "gh",
	Short: "Utilities for working with GitHub repositories",
}

type ghCliToken string

type ghConf struct {
	Token string `yaml:"oauth_token"`
	User  string `yaml:"user"`
}

func (c ghCliToken) Token() (*oauth2.Token, error) {
	filename := strings.ReplaceAll(string(c), "~", os.Getenv("HOME"))
	f, err := os.Open(filename)
	if err != nil {
		return nil, fmt.Errorf("run `gh auth login`. error: %w", err)
	}
	defer f.Close()
	raw, err := io.ReadAll(f)
	if err != nil {
		return nil, fmt.Errorf("yaml read: %w", err)
	}
	t := map[string]ghConf{}
	err = yaml.Unmarshal(raw, t)
	if err != nil {
		return nil, fmt.Errorf("yaml parse: %w", err)
	}
	githubHost, ok := t["github.com"]
	if !ok {
		return nil, fmt.Errorf("no github host found in %s", c)
	}
	return &oauth2.Token{
		AccessToken: githubHost.Token,
		TokenType:   "Bearer",
	}, nil
}

func Client(ctx context.Context) *github.Client {
	ts := ghCliToken("~/.config/gh/hosts.yml")
	return github.NewClient(oauth2.NewClient(ctx, ts))
}

var Repo string

func init() {
	root.RootCmd.AddCommand(GhCmd)
	GhCmd.PersistentFlags().StringVarP(&Repo, "repo", "r", "", "Repository name")
}
