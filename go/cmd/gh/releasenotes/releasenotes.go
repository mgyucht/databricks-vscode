package releasenotes

import (
	"deco/cmd/gh"
	"fmt"
	"log"
	"regexp"
	"sort"
	"strings"

	"github.com/google/go-github/v45/github"
	"github.com/spf13/cobra"
)

var releaseNotes = &cobra.Command{
	Use:   "release-notes",
	Short: "Get release notes template",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := cmd.Context()
		client := gh.Client(ctx)
		tags, _, err := client.Repositories.ListTags(ctx, gh.Org, gh.Repo,
			&github.ListOptions{
				Page:    0,
				PerPage: 1,
			})
		if err != nil {
			return err
		}
		lastRelease := tags[0]
		cmp, _, err := client.Repositories.CompareCommits(ctx, gh.Org, gh.Repo,
			lastRelease.GetName(), Head, nil)
		if err != nil {
			return err
		}

		lines := []string{}
		for _, commit := range cmp.Commits {
			msg := strings.Split(commit.Commit.GetMessage(), "\n")[0]

			prLink := fmt.Sprintf("[#$1](https://github.com/%s/%s/pull/$1)", gh.Org, gh.Repo)
			msg = issueNre.ReplaceAllString(msg, prLink)

			registryDsLink := "[databricks_$1](https://registry.terraform.io/" +
				"providers/databricks/databricks/latest/docs/data-sources/$1) data "
			msg = dataSourceRe.ReplaceAllString(msg, registryDsLink)

			registryResLink := "[databricks_$1](https://registry.terraform.io/" +
				"providers/databricks/databricks/latest/docs/resources/$1)"
			msg = resourceRe.ReplaceAllString(msg, registryResLink)

			msg = fmt.Sprintf(" * %s.", msg)

			lines = append(lines, msg)
		}
		sort.Strings(lines)

		buf := []string{}
		buf = append(buf, "# Preview")
		buf = append(buf, strings.Join(lines, "\n"))
		buf = append(buf, "\n# Markdown")
		buf = append(buf, "```md")
		buf = append(buf, strings.Join(lines, "\n"))
		buf = append(buf, "```")
		summary := strings.Join(buf, "\n")
		log.Printf("[INFO] %s", summary)
		return nil
	},
}

var issueNre = regexp.MustCompile(`(?m)#(\d+)`)
var dataSourceRe = regexp.MustCompile(`(?m)\x60databricks_(\w+)\x60 data `)
var resourceRe = regexp.MustCompile(`(?m)\x60databricks_(\w+)\x60`)

var Head string

func init() {
	gh.GhCmd.AddCommand(releaseNotes)
	releaseNotes.Flags().StringVar(&Head, "head", "master", "head commit ref")
}
