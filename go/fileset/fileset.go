package fileset

import (
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"regexp"
	"strings"
)

type FileSet []File

func (fi FileSet) Exists(pathRegex, needleRegex string) bool {
	path := regexp.MustCompile(pathRegex)
	needle := regexp.MustCompile(needleRegex)
	for _, v := range fi {
		if !path.MatchString(v.Absolute) {
			continue
		}
		if v.Match(needle) {
			return true
		}
	}
	return false
}

type File struct {
	fs.DirEntry
	Absolute string
}

func (fi File) Ext(suffix string) bool {
	return strings.HasSuffix(fi.Name(), suffix)
}

func (fi File) MustMatch(needle string) bool {
	return fi.Match(regexp.MustCompile(needle))
}

func (fi File) Match(needle *regexp.Regexp) bool {
	raw, err := fi.Raw()
	if err != nil {
		log.Printf("[ERROR] read %s: %s", fi.Absolute, err)
		return false
	}
	return needle.Match(raw)
}

func (fi File) Raw() ([]byte, error) {
	f, err := os.Open(fi.Absolute)
	if err != nil {
		return nil, err
	}
	return io.ReadAll(f)
}

func RecursiveChildren(dir string) (found FileSet, err error) {
	queue, err := ReadDir(dir)
	if err != nil {
		return nil, err
	}
	for len(queue) > 0 {
		current := queue[0]
		queue = queue[1:]
		if !current.IsDir() {
			found = append(found, current)
			continue
		}
		if current.Name() == "vendor" {
			continue
		}
		if current.Name() == "scripts" {
			continue
		}
		children, err := ReadDir(current.Absolute)
		if err != nil {
			return nil, err
		}
		queue = append(queue, children...)
	}
	return found, nil
}

func ReadDir(dir string) (queue []File, err error) {
	f, err := os.Open(dir)
	if err != nil {
		return
	}
	defer f.Close()
	dirs, err := f.ReadDir(-1)
	if err != nil {
		return
	}
	for _, v := range dirs {
		absolute := path.Join(dir, v.Name())
		queue = append(queue, File{v, absolute})
	}
	return
}
