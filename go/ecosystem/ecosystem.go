package ecosystem

import (
	"context"
	"deco/ecosystem/reporting"
	"deco/fileset"
)

type TestRunner interface {
	Detect(files fileset.FileSet) bool
	ListAll(files fileset.FileSet) []string
	RunOne(ctx context.Context, files fileset.FileSet, one string) error
	RunAll(ctx context.Context, files fileset.FileSet) (reporting.TestReport, error)
}
