package all

import (
	"deco/cmd/env/test"
	"deco/ecosystem"
	"fmt"
	"log"
	"os"
	"path"

	"github.com/sethvargo/go-githubactions"
	"github.com/spf13/cobra"
)

var allCmd = &cobra.Command{
	Use:   "all",
	Short: "Runs all tests",
	RunE: func(cmd *cobra.Command, args []string) error {
		repo, files, err := test.CheckoutFileset()
		if err != nil {
			return err
		}
		var runner ecosystem.TestRunner
		for _, v := range test.Runners {
			if v.Detect(files) {
				runner = v
			}
		}
		if runner == nil {
			return fmt.Errorf("no supported ecosystem detected")
		}
		report, allTestsResult := runner.RunAll(cmd.Context(), files)
		log.Printf("[INFO] %s", report)

		if os.Getenv("GITHUB_STEP_SUMMARY") != "" {
			githubactions.AddStepSummary(report.StepSummary())
		}
		// TODO: add as report to github and artifact
		// https://github.com/marketplace/actions/upload-a-build-artifact
		// upload artifact apis are a bit involved at the moment...
		// but perhaps we can really make it work...
		//   const artifactUrl = `${env.ACTIONS_RUNTIME_URL}_apis/pipelines/workflows/${env.GITHUB_RUN_ID}/artifacts?api-version=6.0-preview`
		err = report.WriteReport(repo, path.Join(files.Root(), "../../dist/test-report.json"))
		if err != nil {
			log.Printf("[ERR] %s", err)
		}
		return allTestsResult
	},
}

func init() {
	test.TestCmd.AddCommand(allCmd)
}
