package main

import (
	_ "deco/cmd/api"
	_ "deco/cmd/env"
	_ "deco/cmd/env/cleanup"
	_ "deco/cmd/env/export"
	_ "deco/cmd/env/list"
	_ "deco/cmd/env/test"
	_ "deco/cmd/gh"
	_ "deco/cmd/gh/checkoutpr"
	_ "deco/cmd/gh/releasenotes"
	_ "deco/cmd/gh/updateprs"
	"deco/cmd/root"
	_ "deco/cmd/version"
)

func main() {
	root.RootCmd.Execute()
}
