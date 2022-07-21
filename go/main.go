package main

import (
	_ "deco/cmd/api"
	_ "deco/cmd/cleanup"
	"deco/cmd/root"
)

func main() {
	root.RootCmd.Execute()
}
