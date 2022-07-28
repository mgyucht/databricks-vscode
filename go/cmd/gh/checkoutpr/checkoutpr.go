package checkoutpr

import (
	"deco/cmd/gh"
	"log"
	"os/exec"

	"github.com/spf13/cobra"
)

var checkoutPr = &cobra.Command{
	Use:   "checkout-pr",
	Short: "Checks out PR for testing",
	RunE: func(cmd *cobra.Command, args []string) error {
		ctx := cmd.Context()
		client := gh.Client(ctx)
		pr, _, err := client.PullRequests.Get(ctx, gh.Org, gh.Repo, Pr)
		if err != nil {
			return err
		}
		ref := pr.Head.GetRef()
		cloneUrl := pr.Head.Repo.GetCloneURL()
		log.Printf("[INFO] Cloning PR#%d from %s", Pr, cloneUrl)
		res, err := exec.CommandContext(ctx, "git", "clone", cloneUrl,
			"--branch", ref, "ext/"+gh.Repo).Output()
		if err != nil {
			return err
		}
		log.Printf("[INFO] clone result: %s", res)
		return nil
	},
}

var Pr int

func init() {
	gh.GhCmd.AddCommand(checkoutPr)
	checkoutPr.Flags().IntVar(&Pr, "pr", 0, "pull request number")
	checkoutPr.MarkFlagRequired("pr")
}
