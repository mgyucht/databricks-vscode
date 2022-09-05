package folders

import (
	"errors"
	"fmt"
	"os"
	"os/exec"
	"path"
	"path/filepath"
)

func findDirWithLeaf(leaf string, dir string) (string, error) {
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

// This function assumes your deco binary in PATH is a symlink pointing
// to a deco binary in the eng-dev-ecosystem repository
func FindEngDevEcosystemRoot() (string, error) {
	decoBinaryPath, err := exec.LookPath("deco")
	if err != nil {
		return "", fmt.Errorf("cannot find path for deco binary: %s", err)
	}

	// binary in PATH should be syslinked to a binary in eng-dev-ecosystem repository
	decoBinaryInEngDevEcosystem, err := filepath.EvalSymlinks(decoBinaryPath)
	if err != nil {
		return "", err
	}

	engDevEcosystemRoot, err := findDirWithLeaf(".git", filepath.Dir(decoBinaryInEngDevEcosystem))
	return engDevEcosystemRoot, err
}
