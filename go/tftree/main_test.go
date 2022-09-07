package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDiscover(t *testing.T) {
	_, err := discoverGraph("../../ops")
	assert.NoError(t, err)
}

// Note(@pietern): Test is disabled because it requires a dirty working tree to pass.
// func TestChangedFilesInRepo(t *testing.T) {
// 	files, err := changedFoldersInRepo()
// 	assert.NoError(t, err)
// 	assert.True(t, len(files) > 1)
// }

func TestDo(t *testing.T) {
	_, err := planAll()
	assert.NoError(t, err)
}
