package folders

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
)

func findDirWithLeaf(dir string, leaf string) (string, error) {
	for {
		_, err := os.Stat(fmt.Sprintf("%s/%s", dir, leaf))
		if errors.Is(err, os.ErrNotExist) {
			// TODO: test on windows
			next := path.Dir(dir)
			if dir == next { // or stop at $HOME?..
				return "", fmt.Errorf("cannot find %s anywhere", leaf)
			}
			dir = next
			continue
		}
		if err != nil {
			return "", err
		}
		return dir, nil
	}
}

// This function assumes
// EITHER
// your deco binary in $PATH is a symlink pointing to a deco binary in the
// eng-dev-ecosystem repository and you called this function with args[0] == "deco"
// eg. `deco env list`
// OR
// The current working directory is or is in eng-dev-ecosystem repo
// eg. `go run main.go env list`
func FindEngDevEcosystemRoot() (string, error) {
	const DECO_CMD = "deco"
	if os.Args[0] != DECO_CMD {
		wd, err := os.Getwd()
		if err != nil {
			return "", fmt.Errorf("cannot find $PWD: %s", err)
		}
		return findDirWithLeaf(wd, ".git")
	}

	decoBinaryPath, err := exec.LookPath(DECO_CMD)
	if err != nil {
		return "", fmt.Errorf("cannot find path for deco binary: %s", err)
	}

	// binary in PATH should be symlinked to a binary in eng-dev-ecosystem repository
	// Please look at ~/eng-dev-ecosystem/go/Read.me for instructions on how to symlink the
	// binary executable
	decoBinaryInEngDevEcosystem, err := filepath.EvalSymlinks(decoBinaryPath)
	if err != nil {
		return "", err
	}

	engDevEcosystemRoot, err := findDirWithLeaf(filepath.Dir(decoBinaryInEngDevEcosystem), ".git")
	return engDevEcosystemRoot, err
}
