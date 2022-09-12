package golang

import (
	"bufio"
	"context"
	"deco/cmd/env"
	"deco/ecosystem/reporting"
	"deco/fileset"
	"deco/testenv"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"os"
	"os/exec"
	"regexp"
	"strings"
	"sync"
	"time"

	"github.com/nxadm/tail"
)

type GoTestRunner struct{}

func (r GoTestRunner) Detect(files fileset.FileSet) bool {
	return files.Exists(`go.mod`, `module .*\n`)
}

func (r GoTestRunner) ListAll(files fileset.FileSet) (all []string) {
	found, _ := files.FindAll(`_test.go`, `func (TestAcc\w+)\(t`)
	for _, v := range found {
		all = append(all, v...)
	}
	return all
}

func (r GoTestRunner) setCmdEnv(cmd *exec.Cmd, vars map[string]string) error {
	// run test with current environment
	cmd.Env = os.Environ()
	// and variables from test environment
	for k, v := range vars {
		cmd.Env = append(cmd.Env, fmt.Sprintf(`%s=%s`, k, v))
		if strings.HasSuffix(k, "_TOKEN") ||
			strings.HasSuffix(k, "_CREDENTIALS") ||
			strings.HasSuffix(k, "_PASSWORD") ||
			strings.HasSuffix(k, "_SAS") ||
			strings.HasSuffix(k, "_KEY") ||
			strings.HasSuffix(k, "_SECRET") {
			log.Printf("[DEBUG][ENV] %s=***", k)
			continue
		}
		log.Printf("[DEBUG][ENV] %s=%s", k, v)
	}
	return nil
}

func (r GoTestRunner) RunOne(ctx context.Context, files fileset.FileSet, one string) error {
	found := files.FirstMatch(`_test.go`, fmt.Sprintf(`func %s\(`, one))
	if found == nil {
		return fmt.Errorf("test %s not found", one)
	}
	log.Printf("[INFO] found test in %s", found.Dir())

	// make sure to sync on writing to stdout
	reader, writer := io.Pipe()
	defer reader.Close()
	defer writer.Close()

	// go test . -run '^TestResourceClusterRead$' -v
	cmd := exec.Command("go", "test", ".", "-v", "-run", fmt.Sprintf("^%s$", one))
	cmd.Stdout = writer
	cmd.Stderr = writer
	cmd.Dir = found.Dir()

	// retrieve environment variables for a specified test environment
	// TODO: pull up
	vars, err := testenv.EnvVars(ctx, env.GetName())
	if err != nil {
		return err
	}
	err = r.setCmdEnv(cmd, vars)
	if err != nil {
		return err
	}
	// create temp file to forward logs produced by subprocess of subprocess
	debug, err := os.CreateTemp("/tmp", fmt.Sprintf("debug-%s-*.log", one))
	if err != nil {
		return err
	}
	defer debug.Close()
	defer os.Remove(debug.Name())
	tailer, err := tail.TailFile(debug.Name(), tail.Config{Follow: true})
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
	cmd.Env = append(cmd.Env, "TF_LOG=DEBUG")
	cmd.Env = append(cmd.Env, "TF_LOG_SDK=INFO")
	cmd.Env = append(cmd.Env, fmt.Sprintf("TF_LOG_PATH=%s", debug.Name()))

	return cmd.Run()
}

func (r GoTestRunner) RunAll(ctx context.Context, files fileset.FileSet) (results reporting.TestReport, err error) {
	goMod := files.FirstMatch(`go.mod`, `module .*\n`)
	if goMod == nil {
		return nil, fmt.Errorf("%s has no module file", files.Root())
	}
	raw, err := goMod.Raw()
	if err != nil {
		return nil, err
	}
	lines := strings.Split(string(raw), "\n")
	module := strings.Split(lines[0], " ")[1]

	// make sure to sync on writing to stdout
	pipeReader, pipeWriter := io.Pipe()

	// TODO: pull up
	// retrieve environment variables for a specified test environment
	vars, err := testenv.EnvVars(ctx, env.GetName())
	if err != nil {
		return nil, err
	}

	// certain environments need to further filter down the set of tests to run,
	// hence the `TEST_FILTER` environment variable (for now) with `TestAcc` as
	// the default prefix.
	testFilter, ok := vars["TEST_FILTER"]
	if !ok {
		testFilter = "TestAcc"
	}
	cmd := exec.Command("go", "test", "-json", "./...", "-run", fmt.Sprintf("^%s", testFilter))
	cmd.Stdout = pipeWriter
	cmd.Stderr = pipeWriter
	cmd.Dir = files.Root()
	err = r.setCmdEnv(cmd, vars)
	if err != nil {
		return nil, err
	}

	// Tee into file so we can debug issues with logic below.
	teeFile, err := os.OpenFile("test.log", os.O_CREATE|os.O_TRUNC|os.O_WRONLY, 0644)
	if err != nil {
		log.Printf("[ERROR] unable to open log file: %s", err)
		return nil, err
	}
	defer teeFile.Close()
	reader := io.TeeReader(pipeReader, teeFile)

	// We have to wait for the output to be fully processed before returning.
	var wg sync.WaitGroup
	wg.Add(1)

	go func() {
		defer wg.Done()

		output := map[string][]string{}
		scanner := bufio.NewScanner(reader)
		var err error
		var re = regexp.MustCompile(`(?mUs)Error:\s+(.*)Test:\s+`)
		for scanner.Scan() {
			var evt goTestEvent
			line := scanner.Bytes()
			err = json.Unmarshal(line, &evt)
			if err != nil {
				log.Printf("[ERROR] cannot parse JSON line: %s - %s", err, string(line))
				return
			}
			if evt.Test == "" {
				continue
			}
			evt.Package = strings.ReplaceAll(evt.Package, module+"/", "")
			key := fmt.Sprintf("%s/%s", evt.Package, evt.Test)
			switch evt.Action {
			case "output":
				output[key] = append(output[key], evt.Output)
			case "pass":
				results = append(results, reporting.TestResult{
					Time:    evt.Time,
					Package: evt.Package,
					Name:    evt.Test,
					Pass:    true,
					Elapsed: evt.Elapsed,
				})
				log.Printf("[INFO] ✅ %s (%0.3fs)", evt.Test, evt.Elapsed)
			case "skip":
				testLog := strings.Join(output[key], "")
				// filter out "package contains no tests"
				results = append(results, reporting.TestResult{
					Time:    evt.Time,
					Package: evt.Package,
					Name:    evt.Test,
					Skip:    true,
					Output:  testLog,
					Elapsed: evt.Elapsed,
				})
				log.Printf("[DEBUG] 🦥 %s: %s", evt.Test, testLog)
			case "fail":
				testLog := strings.Join(output[key], "")
				results = append(results, reporting.TestResult{
					Time:    evt.Time,
					Package: evt.Package,
					Name:    evt.Test,
					Output:  testLog,
					Elapsed: evt.Elapsed,
				})
				concise := re.FindAllString(testLog, -1)
				log.Printf("[INFO] ❌ %s (%0.3fs)\n%s",
					evt.Test, evt.Elapsed, strings.Join(concise, "\n"))
			default:
				continue
			}
		}
		err = scanner.Err()
		if err != nil && err != io.ErrClosedPipe {
			log.Printf("[ERROR] cannot scan json lines: %s", err)
			return
		}
	}()

	err = cmd.Run()

	// The process has terminated; close the writer it had been writing into.
	pipeWriter.Close()

	// Wait for the goroutine above to finish appending to `results`.
	wg.Wait()

	return results, err
}

type goTestEvent struct {
	Time    time.Time // encodes as an RFC3339-format string
	Action  string
	Package string
	Test    string
	Elapsed float64 // seconds
	Output  string
}
