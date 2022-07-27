package main

import (
	_ "deco/cmd/api"
	_ "deco/cmd/env"
	_ "deco/cmd/env/cleanup"
	_ "deco/cmd/env/export"
	_ "deco/cmd/env/list"
	_ "deco/cmd/gh"
	_ "deco/cmd/gh/updateprs"
	"deco/cmd/root"
)

func main() {
	root.RootCmd.Execute()
}
