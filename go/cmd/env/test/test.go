package cleanup

import (
	"deco/cmd/env"
	"deco/ecosystem"
	"deco/ecosystem/golang"
	"deco/fileset"
	"deco/folders"
	"fmt"
	"log"
	"os"

	"github.com/sethvargo/go-githubactions"
	"github.com/spf13/cobra"
)

var runners = []ecosystem.TestRunner{
	golang.GoTestRunner{},
}

var testDebugCmd = &cobra.Command{
	Use:   "test-debug",
	Short: "Runs a test on environment",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		projectRoot, err := folders.FindDirWithLeaf(".git")
		if err != nil {
			return err
		}
		checkout := fmt.Sprintf("%s/ext/%s", projectRoot, Repo)
		files, err := fileset.RecursiveChildren(checkout)
		if err != nil {
			return err
		}
		var runner ecosystem.TestRunner
		for _, v := range runners {
			if v.Detect(files) {
				runner = v
			}
		}
		if runner == nil {
			return fmt.Errorf("no supported ecosystem detected")
		}
		return runner.RunOne(cmd.Context(), files, args[0])
	},
}

// TODO: this as to split into a dedicated file.
var testCmd = &cobra.Command{
	Use:   "test-all",
	Short: "Runs all tests",
	RunE: func(cmd *cobra.Command, args []string) error {
		projectRoot, err := folders.FindDirWithLeaf(".git")
		if err != nil {
			return err
		}
		// TODO: perhaps with deco CLI we can make it into other repos as well
		checkout := fmt.Sprintf("%s/ext/%s", projectRoot, Repo)
		files, err := fileset.RecursiveChildren(checkout)
		if err != nil {
			return err
		}
		var runner ecosystem.TestRunner
		for _, v := range runners {
			if v.Detect(files) {
				runner = v
			}
		}
		if runner == nil {
			return fmt.Errorf("no supported ecosystem detected")
		}
		// TODO: figure out a better strategy, fail command on error
		report, _ := runner.RunAll(cmd.Context(), files, checkout)
		log.Printf("[INFO] %s", report)

		if os.Getenv("GITHUB_STEP_SUMMARY") != "" {
			githubactions.AddStepSummary(report.StepSummary())
		}
		// TODO: add as report to github and artifact
		// https://github.com/marketplace/actions/upload-a-build-artifact
		// upload artifact apis are a bit involved at the moment...
		// but perhaps we can really make it work...
		//   const artifactUrl = `${env.ACTIONS_RUNTIME_URL}_apis/pipelines/workflows/${env.GITHUB_RUN_ID}/artifacts?api-version=6.0-preview`

		return report.WriteReport(Repo, fmt.Sprintf("%s/dist/test-report.json", projectRoot))
	},
}

var Repo string

func init() {
	env.EnvCmd.AddCommand(testDebugCmd)
	env.EnvCmd.AddCommand(testCmd)

	testDebugCmd.PersistentFlags().StringVarP(&Repo, "repo", "r",
		"terraform-provider-databricks", "Repo name")
	testCmd.PersistentFlags().StringVarP(&Repo, "repo", "r",
		"terraform-provider-databricks", "Repo name")
}
