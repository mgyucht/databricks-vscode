package cov

import (
	"deco/cmd/env/test"
	"deco/fileset"
	"fmt"
	"os"
	"path/filepath"
	"strings"

	"github.com/databricks/databricks-sdk-go/logger"
	"github.com/databricks/databricks-sdk-go/openapi/code"
	"github.com/spf13/cobra"
)

type check struct {
	File      string
	FileMatch string
	Service   string
	Method    func(t *fileset.File, m *code.Method) bool
}

var conventions = map[string]check{
	"go": {
		File:      `internal/%s_test.go`, // internal/clusters_test.go
		FileMatch: `package internal`,    // prelude
		Service:   `.%s.`,                // .Clusters.
		Method: func(t *fileset.File, m *code.Method) bool {
			return t.MustMatch(fmt.Sprintf(`.%s.%s`, m.Service.Name, m.PascalName()))
		},
	},
}

var covCmd = &cobra.Command{
	Use:   "cov",
	Short: "SDK OpenAPI integration test coverage",
	RunE: func(cmd *cobra.Command, args []string) error {
		repo, files, err := test.CheckoutFileset()
		if err != nil {
			return err
		}
		split := strings.Split(repo, "-")
		if len(split) != 3 || split[1] != "sdk" {
			return fmt.Errorf("%s is not an sdk repo", repo)
		}
		chk, ok := conventions[split[2]]
		if !ok {
			return fmt.Errorf("%s has no checks yet", repo)
		}
		home, err := os.UserHomeDir()
		if err != nil {
			return fmt.Errorf("home: %w", err)
		}
		specFile := filepath.Join(home, "universe/bazel-bin/openapi/all-internal.json")
		openapi, err := code.NewFromFile(specFile)
		if err != nil {
			return fmt.Errorf("most likely you didn't run bazel build openapi/all-internal.json: %w", err)
		}
		for _, pkg := range openapi.Packages() {
			t := files.FirstMatch(fmt.Sprintf(chk.File, pkg.Name), chk.FileMatch)
			if t == nil {
				logger.Warnf("Package %s has no tests", pkg.Name)
				continue
			}
			for _, svc := range pkg.Services() {
				if !t.MustMatch(fmt.Sprintf(chk.Service, svc.Name)) {
					logger.Warnf("Service %s has no tests", svc.FullName())
					continue
				}
				for _, m := range svc.Methods() {
					if !chk.Method(t, m) {
						logger.Warnf("Method %s.%s has no tests", svc.FullName(), m.CamelName())
						continue
					}
				}
			}
		}
		return nil
	},
}

func init() {
	test.TestCmd.AddCommand(covCmd)
}
