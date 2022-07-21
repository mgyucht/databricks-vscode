package tf

import (
	"deco/fileset"
	"fmt"
	"strings"

	"github.com/hashicorp/hcl/v2"
	"github.com/hashicorp/hcl/v2/hclparse"
	"github.com/hashicorp/hcl/v2/hclsyntax"
	"github.com/zclconf/go-cty/cty"
)

type TfFile struct {
	File fileset.File
	Body *hclsyntax.Body
}

func New(name string) (*TfFile, error) {
	return NewFromFile(fileset.File{
		Absolute: name,
	})
}

func NewFromFile(fi fileset.File) (*TfFile, error) {
	raw, err := fi.Raw()
	if err != nil {
		return nil, err
	}
	parser := hclparse.NewParser()
	hclf, diags := parser.ParseHCL(raw, fi.Absolute)
	if diags.HasErrors() {
		return nil, fmt.Errorf(diags.Error())
	}
	body, ok := hclf.Body.(*hclsyntax.Body)
	if !ok {
		return nil, fmt.Errorf("body is not a file")
	}
	return &TfFile{
		File: fi,
		Body: body,
	}, nil
}

func (tf *TfFile) foreachDown(block *hclsyntax.Block,
	cb func(*Block) error,
	current, expected []string) error {
	if strings.Join(current, ".") == strings.Join(expected, ".") {
		// found expected block
		return cb(&Block{block})
	}
	for _, child := range block.Body.Blocks {
		err := tf.foreachDown(child, cb, append(current, child.Type), expected)
		if err != nil {
			return err
		}
	}
	return nil
}

func (tf *TfFile) ForEach(cb func(*Block) error, path ...string) error {
	for _, block := range tf.Body.Blocks {
		err := tf.foreachDown(block, cb, []string{block.Type}, path)
		if err != nil {
			return err
		}
	}
	return nil
}

func (tf *TfFile) MustForEach(cb func(*Block), path ...string) {
	tf.ForEach(func(b *Block) error {
		cb(b)
		return nil
	}, path...)
}

type Block struct {
	*hclsyntax.Block
}

func (b *Block) AttrOrErr(key string) (*cty.Value, error) {
	ec := &hcl.EvalContext{}
	source, ok := b.Body.Attributes[key]
	if !ok {
		return nil, fmt.Errorf("key %s not found", key)
	}
	val, diags := source.Expr.Value(ec)
	if diags.HasErrors() {
		return nil, fmt.Errorf(diags.Error())
	}
	return &val, nil
}

func (b *Block) MustStrAttr(key string) string {
	v, _ := b.AttrOrErr(key)
	return v.AsString()
}
