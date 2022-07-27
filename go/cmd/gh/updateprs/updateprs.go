package updateprs

import (
	"deco/cmd/gh"
	"log"

	"github.com/google/go-github/v45/github"
	"github.com/spf13/cobra"
)

var updatePrs = &cobra.Command{
	Use:   "update-prs",
	Short: "Listing all environments",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := cmd.Context()
		client := gh.Client(ctx)

		commits, _, err := client.Repositories.ListCommits(ctx, "databricks", gh.Repo,
			&github.CommitsListOptions{
				SHA: "master",
				ListOptions: github.ListOptions{
					PerPage: 1,
					Page:    0,
				},
			})
		if err != nil {
			return err
		}
		lastCommit := commits[0]
		// todo: truncate string
		log.Printf("[INFO] Last commit is `%s` (%s)", lastCommit.Commit.GetMessage(),
			lastCommit.GetSHA())
		prs, _, err := client.PullRequests.List(ctx, "databricks", gh.Repo, nil)
		if err != nil {
			return err
		}
		for _, pr := range prs {
			if pr.GetNumber() != 1497 {
				continue
			}
			log.Printf("[INFO] Updating #%d (%s) to %s", pr.GetNumber(), pr.GetTitle(),
				lastCommit.GetSHA())
			resp, _, err := client.PullRequests.UpdateBranch(ctx, "databricks", gh.Repo, pr.GetNumber(),
				&github.PullRequestBranchUpdateOptions{
					ExpectedHeadSHA: pr.Head.SHA,
				})
			if err != nil {
				return err
			}
			log.Printf("[INFO] Updating #%d to %s: %s", pr.GetNumber(), lastCommit.GetSHA(),
				resp.GetMessage())
		}
		return nil
	},
}

func init() {
	gh.GhCmd.AddCommand(updatePrs)
}
