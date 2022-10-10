package fileset

import (
	"fmt"
	"io"
	"io/fs"
	"log"
	"os"
	"path"
	"regexp"
	"strings"
)

type FileSet []File

func (fi FileSet) Root() string {
	return strings.TrimSuffix(fi[0].Absolute, "/"+fi[0].Relative)
}

func (fi FileSet) FirstMatch(pathRegex, needleRegex string) *File {
	path := regexp.MustCompile(pathRegex)
	needle := regexp.MustCompile(needleRegex)
	for _, v := range fi {
		if !path.MatchString(v.Absolute) {
			continue
		}
		if v.Match(needle) {
			return &v
		}
	}
	return nil
}

func (fi FileSet) FindAll(pathRegex, needleRegex string) (map[File][]string, error) {
	path := regexp.MustCompile(pathRegex)
	needle := regexp.MustCompile(needleRegex)
	all := map[File][]string{}
	for _, v := range fi {
		if !path.MatchString(v.Absolute) {
			continue
		}
		vall, err := v.FindAll(needle)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", v.Relative, err)
		}
		all[v] = vall
	}
	return all, nil
}

func (fi FileSet) Exists(pathRegex, needleRegex string) bool {
	m := fi.FirstMatch(pathRegex, needleRegex)
	return m != nil
}

type File struct {
	fs.DirEntry
	Absolute string
	Relative string
}

func (fi File) Ext(suffix string) bool {
	return strings.HasSuffix(fi.Name(), suffix)
}

func (fi File) Dir() string {
	return path.Dir(fi.Absolute)
}

func (fi File) MustMatch(needle string) bool {
	return fi.Match(regexp.MustCompile(needle))
}

func (fi File) FindAll(needle *regexp.Regexp) (all []string, err error) {
	raw, err := fi.Raw()
	if err != nil {
		log.Printf("[ERROR] read %s: %s", fi.Absolute, err)
		return nil, err
	}
	for _, v := range needle.FindAllStringSubmatch(string(raw), -1) {
		all = append(all, v[1])
	}
	return all, nil
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
			current.Relative = strings.ReplaceAll(current.Absolute, dir+"/", "")
			found = append(found, current)
			continue
		}
		if current.Name() == "vendor" {
			continue
		}
		if current.Name() == "scripts" {
			continue
		}
		// ext directory contains external projects at the current project depends
		// on. We should ignore it for listing files in the project
		if current.Name() == "ext" {
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
		queue = append(queue, File{v, absolute, ""})
	}
	return
}
