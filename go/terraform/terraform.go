package terraform

import (
	"context"
	"errors"
	"fmt"
	"os/exec"
	"runtime"
	"strings"

	"github.com/hashicorp/terraform-exec/tfexec"
)

// holds detected terraform executable path
var tfExec string

func NewTerraform(workingDir string) (*tfexec.Terraform, error) {
	execPath, err := detectExecutable(context.Background())
	if err != nil {
		return nil, fmt.Errorf("terraform not installed: %w", err)
	}
	return tfexec.NewTerraform(workingDir, execPath)
}

func detectExecutable(ctx context.Context) (string, error) {
	if tfExec != "" {
		return tfExec, nil
	}
	detector := "which"
	if runtime.GOOS == "windows" {
		detector = "where.exe"
	}
	out, err := execAndPassErr(ctx, detector, "terraform")
	if err != nil {
		return "", err
	}
	tfExec = trimmedS(out)
	return tfExec, nil
}

func execAndPassErr(ctx context.Context, name string, args ...string) ([]byte, error) {
	out, err := exec.CommandContext(ctx, name, args...).Output()
	return out, nicerErr(err)
}

func nicerErr(err error) error {
	if err == nil {
		return nil
	}
	if ee, ok := err.(*exec.ExitError); ok {
		errMsg := trimmedS(ee.Stderr)
		if errMsg == "" {
			errMsg = err.Error()
		}
		return errors.New(errMsg)
	}
	return err
}

func trimmedS(bytes []byte) string {
	return strings.Trim(string(bytes), "\n\r")
}
