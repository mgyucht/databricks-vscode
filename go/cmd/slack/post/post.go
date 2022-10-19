package post

import (
	"bytes"
	"context"
	"deco/cmd/gh"
	"deco/cmd/slack"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"regexp"
	"strconv"
	"strings"

	"github.com/google/go-github/v45/github"
	"github.com/spf13/cobra"
)

const (
	// https://design-system.dev.databricks.com/?path=/docs/design-system-colors--primary-colors
	duboisTextValidationDanger  = "#C82D4C"
	duboisTextValidationSuccess = "#277C43"
)

type Webhook struct {
	Text        string       `json:"text,omitempty"`
	UserName    string       `json:"username,omitempty"`
	IconURL     string       `json:"icon_url,omitempty"`
	IconEmoji   string       `json:"icon_emoji,omitempty"`
	Channel     string       `json:"channel,omitempty"`
	LinkNames   string       `json:"link_names,omitempty"`
	UnfurlLinks bool         `json:"unfurl_links"`
	Attachments []Attachment `json:"attachments,omitempty"`
}

type Attachment struct {
	Fallback   string  `json:"fallback"`
	Pretext    string  `json:"pretext,omitempty"`
	Color      string  `json:"color,omitempty"`
	AuthorName string  `json:"author_name,omitempty"`
	AuthorLink string  `json:"author_link,omitempty"`
	AuthorIcon string  `json:"author_icon,omitempty"`
	Footer     string  `json:"footer,omitempty"`
	Fields     []Field `json:"fields,omitempty"`
}

type Field struct {
	Title string `json:"title,omitempty"`
	Value string `json:"value,omitempty"`
	Short bool   `json:"short,omitempty"`
}

func getenv(name string) (string, error) {
	value := os.Getenv(name)
	if value == "" {
		return "", fmt.Errorf("environment variable not set: %s", name)
	}
	return value, nil
}

func LoadActionStatus(ctx context.Context, run *WorkflowRunClient, jobs []*github.WorkflowJob) (*Webhook, error) {
	githubWorkflow, err := getenv("GITHUB_WORKFLOW")
	if err != nil {
		return nil, err
	}

	slackChannel, err := getenv("SLACK_CHANNEL")
	if err != nil {
		return nil, err
	}

	runURL := fmt.Sprintf("https://github.com/%s/%s/actions/runs/%d", run.Owner, run.Repo, run.RunID)
	text := fmt.Sprintf(":failed: *%s* failed (<%s|run>)", githubWorkflow, runURL)
	wh := Webhook{
		Text:      text,
		UserName:  "eng-dev-ecosystem-bot",
		IconEmoji: ":robot_face:",
		Channel:   slackChannel,
	}

	// Note: Adding an attachment for each job in the workflow run is very verbose.
	// It's disabled at the moment (see loop body to enable it).
	for _, job := range jobs {
		field := Field{
			Title: job.GetName(),
			Short: false,
		}

		duration := job.GetCompletedAt().Time.Sub(job.GetStartedAt().Time)
		attachment := Attachment{}
		if job.GetConclusion() == "success" {
			attachment.Color = duboisTextValidationSuccess
			field.Value = "Succeeded"
		} else {
			attachment.Color = duboisTextValidationDanger
			field.Value = "Failed"
		}

		url := fmt.Sprintf("%s/jobs/%d", runURL, job.GetID())
		field.Value = fmt.Sprintf("%s after %s (<%s|log>)", field.Value, duration, url)
		attachment.Fields = append(attachment.Fields, field)

		// Uncomment line below to include status for each job.
		// wh.Attachments = append(wh.Attachments, attachment)
	}

	return &wh, nil
}

type WorkflowRunClient struct {
	*github.Client
	*github.WorkflowRun

	Owner string
	Repo  string
	RunID int64
}

func NewWorkflowRunClient(ctx context.Context) (*WorkflowRunClient, error) {
	parts := strings.SplitN(os.Getenv("GITHUB_REPOSITORY"), "/", 2)
	runID, err := strconv.ParseInt(os.Getenv("GITHUB_RUN_ID"), 10, 64)
	if err != nil {
		return nil, err
	}

	run := &WorkflowRunClient{
		Client: gh.Client(ctx),

		Owner: parts[0],
		Repo:  parts[1],
		RunID: runID,
	}

	run.WorkflowRun, _, err = run.Actions.GetWorkflowRunByID(ctx, run.Owner, run.Repo, run.RunID)
	if err != nil {
		return nil, err
	}

	return run, nil
}

func (run *WorkflowRunClient) GetJobs(ctx context.Context, pattern string) ([]*github.WorkflowJob, error) {
	jobs, _, err := run.Actions.ListWorkflowJobs(ctx, run.Owner, run.Repo, run.RunID, &github.ListWorkflowJobsOptions{})
	if err != nil {
		return nil, err
	}

	re := regexp.MustCompile(pattern)

	var out []*github.WorkflowJob
	for _, job := range jobs.Jobs {
		if re.MatchString(job.GetName()) {
			out = append(out, job)
		}
	}

	return out, nil
}

func Post(ctx context.Context, run *WorkflowRunClient, jobs []*github.WorkflowJob) error {
	webhook, err := getenv("SLACK_WEBHOOK")
	if err != nil {
		return err
	}

	wh, err := LoadActionStatus(ctx, run, jobs)
	if err != nil {
		return err
	}

	buf, err := json.Marshal(wh)
	if err != nil {
		return err
	}

	res, err := http.DefaultClient.Post(webhook, "application/json", bytes.NewBuffer(buf))
	if err != nil {
		return err
	}

	if res.StatusCode != http.StatusOK {
		return fmt.Errorf("http response: %s", res.Status)
	}

	return nil
}

var post = &cobra.Command{
	Use:   "post-action-status",
	Short: "Post to a Slack webhook URL",
	RunE: func(cmd *cobra.Command, args []string) error {
		run, err := NewWorkflowRunClient(cmd.Context())
		if err != nil {
			return err
		}

		// If this run is not the first attempt, someone must be triggering re-runs.
		// We don't want to spam Slack with notifications for these runs.
		attempt := run.GetRunAttempt()
		if attempt > 1 {
			log.Printf("[INFO] This run is attempt %d; not posting Slack message", attempt)
			return nil
		}

		regexp, err := getenv("GITHUB_JOB_REGEXP")
		if err != nil {
			return err
		}

		jobs, err := run.GetJobs(cmd.Context(), regexp)
		if err != nil {
			return err
		}

		var success = true
		for _, job := range jobs {
			success = success && job.GetConclusion() == "success"
		}

		// Don't notify if these jobs suceeded
		if success {
			log.Printf("[INFO] All jobs successful; not posting Slack message")
			return nil
		}

		log.Printf("[INFO] One or more jobs failed; posting Slack message")
		return Post(cmd.Context(), run, jobs)

	},
}

func init() {
	slack.SlackCmd.AddCommand(post)
}
