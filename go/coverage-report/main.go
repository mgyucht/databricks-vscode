package main

import (
	"deco/fileset"
	"fmt"
	"os"
	"path"
	"sort"
	"strings"

	"github.com/databricks/terraform-provider-databricks/provider"
	"github.com/hashicorp/terraform-plugin-sdk/v2/helper/schema"
)

const providerSubmodule = "../ext/terraform-provider-databricks"
const docsSubmodule = "../ext/docs"

type CoverageReport struct {
	Resources []ResourceCoverage
}

type ResourceCoverage struct {
	Name         string
	Data         bool
	Docs         bool
	OfficialDocs bool
	Readme       bool
	AccTest      bool
	AccFile      bool
	ResFile      bool
	ResTest      bool
	Deprecated   bool
	Fields       []FieldCoverage
}

func (rc ResourceCoverage) Prefixless() string {
	return strings.TrimPrefix(rc.Name, "databricks_")
}

func (rc ResourceCoverage) DocLocation() string {
	if rc.Data {
		return path.Join(providerSubmodule, "docs/data-sources", rc.Prefixless()+".md")
	}
	return path.Join(providerSubmodule, "docs/resources", rc.Prefixless()+".md")
}

func (rc ResourceCoverage) ResourceFilename() string {
	if rc.Data {
		return fmt.Sprintf("data_%s.go", rc.Prefixless())
	}
	return fmt.Sprintf("resource_%s.go", rc.Prefixless())
}

func (rc ResourceCoverage) ResourceFn() string {
	return strings.ReplaceAll(
		strings.Title(
			strings.ReplaceAll(
				rc.Prefixless(), "_", " ")), " ", "")
}

func (rc ResourceCoverage) TestFilename() string {
	if rc.Data {
		return fmt.Sprintf("data_%s_test.go", rc.Prefixless())
	}
	return fmt.Sprintf("resource_%s_test.go", rc.Prefixless())
}

func (rc ResourceCoverage) AccFilename() string {
	return fmt.Sprintf("acceptance/%s_test.go", rc.Prefixless())
}

func (rc ResourceCoverage) coverage(cb func(FieldCoverage) bool, green, yellow int) string {
	var x float32
	for _, v := range rc.Fields {
		if cb(v) {
			x++
		}
	}
	coverage := int(100 * x / float32(len(rc.Fields)))
	coverageStr := fmt.Sprintf("(%d%%)", coverage)
	if coverage > green {
		return fmt.Sprintf("✅ %6s", coverageStr)
	}
	if coverage > yellow {
		return fmt.Sprintf("👎 %6s", coverageStr)
	}
	return fmt.Sprintf("❌ %6s", coverageStr)
}

func (rc ResourceCoverage) DocCoverage() string {
	return rc.coverage(func(fc FieldCoverage) bool {
		return fc.Docs
	}, 80, 50)
}

func (rc ResourceCoverage) AccCoverage() string {
	return rc.coverage(func(fc FieldCoverage) bool {
		return fc.AccTest
	}, 40, 20)
}

func (rc ResourceCoverage) UnitCoverage() string {
	return rc.coverage(func(fc FieldCoverage) bool {
		return fc.UnitTest
	}, 40, 20)
}

type FieldCoverage struct {
	Name     string
	Docs     bool
	AccTest  bool
	UnitTest bool
}

func (fc FieldCoverage) EverythingCovered() bool {
	return fc.Docs && fc.AccTest && fc.UnitTest
}

func newResourceCoverage(files, databricksDocs fileset.FileSet, name string, s map[string]*schema.Schema, data bool) ResourceCoverage {
	r := ResourceCoverage{
		Name:    name,
		Data:    data,
		Readme:  files.Exists("../README.md", name),
		AccTest: files.Exists(`acceptance/.*_test.go`, fmt.Sprintf(`"%s"`, name)),
	}
	r.Docs = fileExists(r.DocLocation())
	r.OfficialDocs = databricksDocs.Exists(`.*.md`, r.Name)
	// acceptance test file with a correct name
	r.AccFile = files.Exists(r.AccFilename(), r.Name)
	// resource file with a correct name
	r.ResFile = files.Exists(r.ResourceFilename(), r.ResourceFn())
	// resource unit test file with a correct name
	r.ResTest = files.Exists(r.TestFilename(), r.ResourceFn())
	r.Fields = fields(r, s, files)
	sort.Slice(r.Fields, func(i, j int) bool {
		return r.Fields[i].Name < r.Fields[j].Name
	})
	return r
}

func main() {
	databricksDocs, err := fileset.RecursiveChildren(docsSubmodule)
	if err != nil {
		panic(err)
	}
	providerFiles, err := fileset.RecursiveChildren(providerSubmodule)
	if err != nil {
		panic(err)
	}

	p := provider.DatabricksProvider()
	var cr CoverageReport
	var longestResourceName, longestFieldName int

	for k, v := range p.ResourcesMap {
		if len(k) > longestResourceName {
			longestResourceName = len(k)
		}
		r := newResourceCoverage(providerFiles, databricksDocs, k, v.Schema, false)
		r.Deprecated = v.DeprecationMessage != ""
		cr.Resources = append(cr.Resources, r)
	}
	for k, v := range p.DataSourcesMap {
		if len(k) > longestResourceName {
			longestResourceName = len(k)
		}
		r := newResourceCoverage(providerFiles, databricksDocs, k, v.Schema, true)
		r.Deprecated = v.DeprecationMessage != ""
		cr.Resources = append(cr.Resources, r)
	}
	sort.Slice(cr.Resources, func(i, j int) bool {
		return cr.Resources[i].Name < cr.Resources[j].Name
	})

	report := os.Stdout
	report.WriteString("| Resource | Readme | Docs | Official Docs | Acceptance Test | Acceptance File | Resource File | Unit test |\n")
	report.WriteString("| --- | --- | --- | --- | --- | --- | --- | --- |\n")
	resSummaryFormat := "| %" + fmt.Sprint(longestResourceName) + "s | %s | %s | %s | %s | %s | %s | %s |\n"
	for _, r := range cr.Resources {
		for _, field := range r.Fields {
			if len(field.Name) > longestFieldName {
				longestFieldName = len(field.Name)
			}
		}
		name := r.Name
		if r.Data {
			name = "* " + name
		}
		report.WriteString(fmt.Sprintf(resSummaryFormat, name,
			checkbox(r.Readme),
			r.DocCoverage(),
			checkbox(r.OfficialDocs),
			r.AccCoverage(),
			checkbox(r.AccFile),
			checkbox(r.ResFile),
			r.UnitCoverage(),
		))
	}
	// TODO: move to a separate file and publish as an artifact
	// report.WriteString("\n\n| Resource | Field | Docs | Acceptance Test | Unit Test |\n")
	// report.WriteString("| --- | --- | --- | --- | --- |\n")
	// fieldSummaryFormat := "| %" + fmt.Sprint(longestResourceName) + "s | %" +
	// 	fmt.Sprint(longestFieldName) + "s | %s | %s | %s |\n"
	// for _, r := range cr.Resources {
	// 	if r.Deprecated {
	// 		continue
	// 	}
	// 	for _, field := range r.Fields {
	// 		if field.EverythingCovered() {
	// 			continue
	// 		}
	// 		report.WriteString(fmt.Sprintf(fieldSummaryFormat,
	// 			r.Name,
	// 			field.Name,
	// 			checkbox(field.Docs),
	// 			checkbox(field.AccTest),
	// 			checkbox(field.UnitTest),
	// 		))
	// 	}
	// }
}

func fields(r ResourceCoverage, s map[string]*schema.Schema, files fileset.FileSet) (fields []FieldCoverage) {
	type pathWrapper struct {
		r    *schema.Resource
		path []string
	}
	queue := []pathWrapper{
		{
			r: &schema.Resource{Schema: s},
		},
	}
	doc := fileset.File{Absolute: r.DocLocation()}

	noisyDuplicates := map[string]bool{
		"new_cluster": true,
		"task":        true,
	}
	for {
		head := queue[0]
		queue = queue[1:]
		for field, v := range head.r.Schema {
			if noisyDuplicates[field] {
				continue
			}
			path := append(head.path, field)
			if nested, ok := v.Elem.(*schema.Resource); ok {
				queue = append(queue, pathWrapper{
					r:    nested,
					path: path,
				})
			}
			fc := FieldCoverage{
				Name: strings.Join(path, "."),
			}
			if v.Computed {
				fc.Name += " (computed)"
			}
			if r.Docs {
				fc.Docs = doc.MustMatch(field)
			}
			if r.AccTest {
				fc.AccTest = files.Exists(`acceptance/.*_test.go`, field)
			}
			if r.ResTest {
				fc.UnitTest = files.Exists(r.TestFilename(), field)
			}
			fields = append(fields, fc)
		}
		if len(queue) == 0 {
			break
		}
	}
	return fields
}

func checkbox(b bool) string {
	if b {
		return "✅"
	}
	return "❌"
}

func fileExists(name string) bool {
	_, err := os.Stat(name)
	return err == nil
}
