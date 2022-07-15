package main

import (
	"deco/fileset"
	"fmt"
	"path"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
	"github.com/hashicorp/hcl/v2/hclsyntax"
)

type Dependency struct {
	Path   string
	AsName string
	InFile string
}

type Graph map[string][]Dependency

type Repo struct {
	Graph Graph
	Roots map[string]bool
}

func do(start string) (*Repo, error) {
	fs, err := fileset.RecursiveChildren(start)
	if err != nil {
		return nil, err
	}
	repo := &Repo{
		Graph: Graph{},
		Roots: map[string]bool{},
	}
	for _, v := range fs {
		if !v.Ext(".tf") {
			continue
		}
		raw, err := v.Raw()
		if err != nil {
			return nil, err
		}

		currdir := path.Dir(v.Absolute)

		parser := hclparse.NewParser()
		hclf, diags := parser.ParseHCL(raw, v.Absolute)
		if diags.HasErrors() {
			return nil, fmt.Errorf(diags.Error())
		}
		body, ok := hclf.Body.(*hclsyntax.Body)
		if !ok {
			continue
		}
		ec := &hcl.EvalContext{}
		for _, block := range body.Blocks {
			if block.Type == "module" {
				source, ok := block.Body.Attributes["source"]
				if !ok {
					continue
				}
				val, diags := source.Expr.Value(ec)
				if diags.HasErrors() {
					return nil, fmt.Errorf(diags.Error())
				}
				label := strings.Join(block.Labels, ".")
				src := val.AsString()
				src = path.Join(currdir, src)
				repo.Graph[src] = append(repo.Graph[src], Dependency{
					Path:   currdir,
					AsName: label,
					InFile: v.Name(),
				})
			}
			if block.Type == "terraform" {
				var isRoot bool
				for _, tb := range block.Body.Blocks {
					if tb.Type == "backend" {
						isRoot = true
					}
				}
				if isRoot {
					repo.Roots[currdir] = true
				}
			}
		}

	}
	return repo, nil
}

func main() {
	_, err := do("../../ops")
	if err != nil {
		panic(err)
	}
}
