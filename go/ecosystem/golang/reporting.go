package golang

import (
	"bufio"
	"deco/ecosystem/reporting"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"regexp"
	"strings"
	"time"
)

// TestEvent is defined at https://pkg.go.dev/cmd/test2json#hdr-Output_Format.
type TestEvent struct {
	Time    time.Time // encodes as an RFC3339-format string
	Action  string
	Package string
	Test    string
	Elapsed float64 // seconds
	Output  string
}

func ReadTestEvents(reader io.Reader) <-chan TestEvent {
	ch := make(chan TestEvent)

	go func() {
		defer close(ch)

		scanner := bufio.NewScanner(reader)
		for scanner.Scan() {
			line := scanner.Bytes()

			var testEvent TestEvent
			err := json.Unmarshal(line, &testEvent)
			if err != nil {
				log.Printf("[ERROR] cannot parse JSON line: %s - %s", err, string(line))
				return
			}

			ch <- testEvent
		}

		err := scanner.Err()
		if err != nil && err != io.ErrClosedPipe {
			log.Printf("[ERROR] cannot scan json lines: %s", err)
			return
		}
	}()

	return ch
}

func collectOutput(testEvents []TestEvent) string {
	var b strings.Builder
	for _, testEvent := range testEvents {
		if testEvent.Action == "output" {
			b.WriteString(testEvent.Output)
		}
	}
	return b.String()
}

func summarize(output string) string {
	var re = regexp.MustCompile(`(?mUs)Error:\s+(.*)Test:\s+`)
	concise := re.FindAllString(output, -1)
	return strings.Join(concise, "\n")
}

func CollectTestReport(ch <-chan TestEvent) (report reporting.TestReport) {
	testEventsByKey := map[string][]TestEvent{}

	for testEvent := range ch {
		if testEvent.Test == "" {
			continue
		}

		// Keep track of all events per test.
		key := fmt.Sprintf("%s/%s", testEvent.Package, testEvent.Test)
		testEventsByKey[key] = append(testEventsByKey[key], testEvent)

		// Only take action on pass/skip/fail
		switch testEvent.Action {
		case "pass":
			testLog := collectOutput(testEventsByKey[key])
			delete(testEventsByKey, key)
			report = append(report, reporting.TestResult{
				Time:    testEvent.Time,
				Package: testEvent.Package,
				Name:    testEvent.Test,
				Pass:    true,
				Skip:    false,
				Output:  testLog,
				Elapsed: testEvent.Elapsed,
			})
			log.Printf("[INFO] ✅ %s (%0.3fs)", testEvent.Test, testEvent.Elapsed)
		case "skip":
			testLog := collectOutput(testEventsByKey[key])
			delete(testEventsByKey, key)
			report = append(report, reporting.TestResult{
				Time:    testEvent.Time,
				Package: testEvent.Package,
				Name:    testEvent.Test,
				Pass:    false,
				Skip:    true,
				Output:  testLog,
				Elapsed: testEvent.Elapsed,
			})
			log.Printf("[DEBUG] 🦥 %s: %s", testEvent.Test, testLog)
		case "fail":
			testLog := collectOutput(testEventsByKey[key])
			delete(testEventsByKey, key)
			report = append(report, reporting.TestResult{
				Time:    testEvent.Time,
				Package: testEvent.Package,
				Name:    testEvent.Test,
				Pass:    false,
				Skip:    false,
				Output:  testLog,
				Elapsed: testEvent.Elapsed,
			})
			log.Printf("[INFO] ❌ %s (%0.3fs)\n%s", testEvent.Test, testEvent.Elapsed, summarize(testLog))
		default:
			continue
		}
	}

	// Mark remaining tests as failed (timed out?)
	for _, testEvents := range testEventsByKey {
		testEvent := testEvents[len(testEvents)-1]
		testLog := collectOutput(testEvents)
		report = append(report, reporting.TestResult{
			Time:    testEvent.Time,
			Package: testEvent.Package,
			Name:    testEvent.Test,
			Pass:    false,
			Skip:    false,
			Output:  testLog,
			Elapsed: testEvent.Elapsed,
		})
		log.Printf("[INFO] ❌ %s (%0.3fs)\n%s", testEvent.Test, testEvent.Elapsed, summarize(testLog))
	}

	return
}
