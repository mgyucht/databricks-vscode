package testpr

import (
	"context"
	"deco/cmd/env"
	"deco/cmd/gh"
	"deco/folders"
	"deco/prompt"
	"fmt"
	"math/rand"
	"os"
	"path"
	"time"

	"github.com/briandowns/spinner"
	"github.com/fatih/color"
	"github.com/pkg/browser"

	"github.com/databricks/databricks-sdk-go/logger"
	"github.com/databricks/databricks-sdk-go/retries"
	"github.com/google/go-github/v45/github"
	"github.com/spf13/cobra"
)

func Spinner(label string, fn func(*spinner.Spinner) error, final string) error {
	rand.Seed(time.Now().UnixMilli())
	s := spinner.New(spinner.CharSets[rand.Intn(11)], 200*time.Millisecond)
	_ = s.Color("green")
	s.Start()
	s.Prefix = " "
	s.Suffix = " " + label

	err := fn(s)
	if err == nil {
		s.FinalMSG = color.GreenString(" ✓ %s", final) // or ✓
	} else {
		s.FinalMSG = color.RedString(" ✗ %s", err) // or
	}
	s.Stop()
	println("")
	return err
}

var mapping = map[string]string{
	"terraform-pr-manual": "terraform-provider-databricks",
	"sdk-go-pr-manual":    "databricks-sdk-go",
	"bricks-pr-manual":    "bricks",
	"vscode-pr-manual":    "vscode",
}

func getOrSelectRepo() (string, string, error) {
	wd, err := os.Getwd()
	if err != nil {
		return "", "", err
	}
	wdRoot, err := folders.FindDirWithLeaf(wd, ".git")
	if err != nil {
		return "", "", err
	}
	manualTriggers := []string{}
	for trg, repo := range mapping {
		if path.Base(wdRoot) == repo {
			return trg, repo, nil
		}
		manualTriggers = append(manualTriggers, trg)
	}
	trigger := prompt.AskString("Trigger", manualTriggers)
	repo, ok := mapping[trigger]
	if !ok {
		return "", "", fmt.Errorf("no triggers for %s", trigger)
	}
	return trigger, repo, nil
}

func getPr(ctx context.Context, client *github.Client, repo string) (*prompt.Answer, error) {
	prs, _, err := client.PullRequests.List(ctx, gh.Org, repo,
		&github.PullRequestListOptions{
			State: "open",
		})
	if err != nil {
		return nil, err
	}
	choices := []prompt.Answer{}
	for _, v := range prs {
		choices = append(choices, prompt.Answer{
			Value:    v.GetTitle(),
			Details:  fmt.Sprint(v.GetNumber()),
			Callback: nil,
		})
	}
	_, pr, _ := prompt.Choice{
		Key:     "pr",
		Label:   "Pull Request",
		Answers: choices,
	}.Ask(prompt.Results{})
	return &pr, nil
}

func triggerAndGetId(ctx context.Context, client *github.Client, trigger, pr string) (int64, error) {
	runs, _, err := client.Actions.ListWorkflowRunsByFileName(
		ctx, gh.Org, "eng-dev-ecosystem", fmt.Sprintf("%s.yml", trigger), nil)
	if err != nil {
		return 0, err
	}
	prevIds := map[int64]bool{}
	for _, v := range runs.WorkflowRuns {
		prevIds[v.GetID()] = true
	}
	_, err = client.Actions.CreateWorkflowDispatchEventByFileName(
		ctx, gh.Org, "eng-dev-ecosystem", fmt.Sprintf("%s.yml", trigger),
		github.CreateWorkflowDispatchEventRequest{
			Ref: "main",
			Inputs: map[string]interface{}{
				"pull_request_number": pr,
				"environment":         env.GetName(),
			},
		})
	if err != nil {
		return 0, err
	}
	// github doesn't return us the workflow run ID
	time.Sleep(5 * time.Second)
	runs, _, err = client.Actions.ListWorkflowRunsByFileName(
		ctx, gh.Org, "eng-dev-ecosystem", fmt.Sprintf("%s.yml", trigger), nil)
	if err != nil {
		return 0, err
	}
	var newId int64
	for _, v := range runs.WorkflowRuns {
		if prevIds[v.GetID()] {
			continue
		}
		newId = v.GetID()
		// i hoped to get the workflow run ID via dispatch response,
		// but it's not possible.
		break
	}
	return newId, nil
}

var testPr = &cobra.Command{
	Use:   "test-pr",
	Short: "Run workflow",
	RunE: func(cmd *cobra.Command, args []string) error {
		trigger, repo, err := getOrSelectRepo()
		if err != nil {
			return err
		}
		ctx := cmd.Context()
		client := gh.Client(ctx)
		pr, err := getPr(ctx, client, repo)
		if err != nil {
			return err
		}
		runId, err := triggerAndGetId(ctx, client, trigger, pr.Details)
		if err != nil {
			return err
		}
		return Spinner("Run", func(s *spinner.Spinner) error {
			_, err := retries.Poll(ctx, 1*time.Hour, func() (*github.WorkflowRun, *retries.Err) {
				run, _, err := client.Actions.GetWorkflowRunByID(ctx, gh.Org, "eng-dev-ecosystem", runId)
				if err != nil {
					return nil, retries.Halt(err)
				}
				s.Suffix = fmt.Sprintf(" %s", run.GetStatus())
				switch run.GetStatus() {
				case "completed":
					return run, nil
				case "failure":
					return nil, retries.Halt(fmt.Errorf("run failed"))
				default:
					return nil, retries.Continue(fmt.Errorf("not complete: %s", run.GetStatus()))
				}
			})
			url := fmt.Sprintf("https://github.com/databricks/eng-dev-ecosystem/actions/runs/%d", runId)
			logger.Infof("URL: %s", url)
			if openBrowser {
				browser.OpenURL(url)
			}
			return err
		}, "Complete")
	},
}

var openBrowser bool

func init() {
	gh.GhCmd.AddCommand(testPr)
	testPr.Flags().BoolVar(&openBrowser, "browser", true, "open browser with workflow run after finished")
}
