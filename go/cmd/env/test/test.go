package cleanup

import (
	"deco/cmd/env"
	"deco/fileset"
	"deco/folders"
	"deco/testenv"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"strings"

	"github.com/nxadm/tail"
	"github.com/spf13/cobra"
)

var testCmd = &cobra.Command{
	Use:   "test",
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
		single := args[0]
		found := files.FirstMatch(`_test.go`, fmt.Sprintf(`func %s\(`, single))
		if found == nil {
			return fmt.Errorf("test %s not found", single)
		}
		log.Printf("[INFO] found test in %s", found.Dir())
		reader, writer := io.Pipe()
		defer reader.Close()
		defer writer.Close()
		// go test . -run '^TestResourceClusterRead$' -v
		c := exec.Command("go", "test", ".", "-v", "-run",
			fmt.Sprintf("^%s$", single))

		vars, err := testenv.EnvVars(cmd.Context(), env.GetName())
		if err != nil {
			return err
		}
		c.Env = os.Environ()
		for k, v := range vars {
			c.Env = append(c.Env, fmt.Sprintf(`%s=%s`, k, v))
			if strings.HasSuffix(k, "_TOKEN") ||
				strings.HasSuffix(k, "_CREDENTIALS") ||
				strings.HasSuffix(k, "_SAS") ||
				strings.HasSuffix(k, "_KEY") ||
				strings.HasSuffix(k, "_SECRET") {
				log.Printf("[INFO][ENV] %s=***", k)
				continue
			}
			log.Printf("[INFO][ENV] %s=%s", k, v)
		}
		// create temp file to forward logs produced by subprocess of subprocess
		tfsdkLog, err := os.CreateTemp("/tmp", fmt.Sprintf("debug-%s-*.log", single))
		if err != nil {
			return err
		}
		defer tfsdkLog.Close()
		defer os.Remove(tfsdkLog.Name())
		logfile := tfsdkLog.Name()
		tailer, err := tail.TailFile(logfile, tail.Config{Follow: true})
		if err != nil {
			return err
		}
		go io.CopyBuffer(os.Stdout, reader, make([]byte, 128))
		go func() {
			for line := range tailer.Lines {
				writer.Write([]byte(line.Text + "\n"))
			}
		}()
		// Terraform debug logging is a bit involved.
		// See https://www.terraform.io/plugin/log/managing
		c.Env = append(c.Env, "TF_LOG=DEBUG")
		c.Env = append(c.Env, "TF_LOG_SDK=INFO")
		c.Env = append(c.Env, fmt.Sprintf("TF_LOG_PATH=%s", logfile))
		c.Dir = found.Dir()
		c.Stdout = writer
		c.Stderr = writer
		return c.Run()
	},
}

var Repo string

func init() {
	env.EnvCmd.AddCommand(testCmd)
	testCmd.PersistentFlags().StringVarP(&Repo, "repo", "r",
		"terraform-provider-databricks", "Repo name")
}
