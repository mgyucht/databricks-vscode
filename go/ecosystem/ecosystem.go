package ecosystem

import (
	"context"
	"deco/ecosystem/reporting"
	"deco/fileset"
)

type TestRunner interface {
	Detect(files fileset.FileSet) bool
	RunOne(ctx context.Context, files fileset.FileSet, one string) error
	RunAll(ctx context.Context, files fileset.FileSet, checkout string) (reporting.TestReport, error)
}
