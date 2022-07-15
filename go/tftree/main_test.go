package main

import (
	"testing"

	"github.com/stretchr/testify/assert"
)

func TestDo(t *testing.T) {
	_, err := do("../../ops")
	assert.NoError(t, err)
}