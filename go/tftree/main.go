package main

import (
	"bytes"
	"context"
	"deco/fileset"
	"fmt"
	"io/ioutil"
	"os"
	"os/exec"
	"path"
	"strings"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/hashicorp/terraform-exec/tfexec"
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

func discoverGraph(start string) (*Repo, error) {
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

func changedFoldersInRepo() (map[string]bool, error) {
	raw, err := exec.CommandContext(context.Background(),
		"git", "--no-pager", "diff", "--name-only").Output()
	if err != nil {
		return nil, err
	}
	changes := map[string]bool{}
	for _, v := range strings.Split(string(raw), "\n") {
		if v == "" {
			continue
		}
		changes["../../"+path.Dir(v)] = true
	}
	return changes, nil
}

func affectedRoots() ([]string, error) {
	graph, err := discoverGraph("../../ops")
	if err != nil {
		return nil, err
	}
	changedDirs, err := changedFoldersInRepo()
	if err != nil {
		return nil, err
	}
	queue := []Dependency{}
	for dir := range changedDirs {
		queue = append(queue, Dependency{
			Path:   dir,
			AsName: "(git change)",
		})
	}
	affectedRoots := []string{}
	for len(queue) > 0 {
		head := queue[0]
		queue = queue[1:]
		queue = append(queue, graph.Graph[head.Path]...)
		if graph.Roots[head.Path] {
			affectedRoots = append(affectedRoots, head.Path)
		}
	}
	return affectedRoots, nil
}

type planResult struct {
	ret bytes.Buffer
	raw string
}

func planInRoot(ctx context.Context, root string) (*planResult, error) {
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.1.0")),
	}
	execPath, err := installer.Install(ctx)
	if err != nil {
		return nil, err
	}
	tf, err := tfexec.NewTerraform(root, execPath)
	if err != nil {
		return nil, err
	}
	err = tf.Init(ctx)
	if err != nil {
		return nil, err
	}
	planFile := ".tfplan"
	changes, err := tf.Plan(ctx, tfexec.Out(planFile))
	if err != nil {
		return nil, err
	}
	if !changes {
		return nil, nil
	}
	var ret bytes.Buffer
	tf.SetStdout(os.Stdout)
	defer tf.SetStdout(ioutil.Discard)
	raw, err := tf.ShowPlanFileRaw(ctx, planFile)
	if err != nil {
		return nil, err
	}
	return &planResult{
		ret: ret,
		raw: raw,
	}, nil
}

func planAll() ([]string, error) {
	roots, err := affectedRoots()
	if err != nil {
		return nil, err
	}
	plans := []string{}
	for _, v := range roots {
		// TODO: this block somehow should become a callback
		// TODO: make it run parallel?..
		// TODO: make DAG of Graph roots and run that in parallel without conflicts.
		res, err := planInRoot(context.TODO(), v)
		if err != nil {
			return nil, fmt.Errorf("%s: %w", v, err)
		}
		if res.raw != "" {
			plans = append(plans, res.raw)
		}
	}
	return plans, nil
}

func main() {
	_, err := planAll()
	if err != nil {
		panic(err)
	}
}
