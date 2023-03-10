package main

import (
	_ "deco/cmd/env"
	_ "deco/cmd/env/api"
	_ "deco/cmd/env/cleanup"
	_ "deco/cmd/env/export"
	_ "deco/cmd/env/flip"
	_ "deco/cmd/env/list"
	_ "deco/cmd/env/run"
	_ "deco/cmd/env/save"
	_ "deco/cmd/env/shell"
	_ "deco/cmd/env/test"
	_ "deco/cmd/env/test/all"
	_ "deco/cmd/env/test/cov"
	_ "deco/cmd/env/test/debug"
	_ "deco/cmd/env/test/list"
	_ "deco/cmd/gh"
	_ "deco/cmd/gh/checkoutpr"
	_ "deco/cmd/gh/releasenotes"
	_ "deco/cmd/gh/testpr"
	_ "deco/cmd/gh/updateprs"
	"deco/cmd/root"
	_ "deco/cmd/slack"
	_ "deco/cmd/slack/post"
	_ "deco/cmd/tf"
	_ "deco/cmd/tf/cov"
	_ "deco/cmd/tf/schemagen"
	_ "deco/cmd/version"

	"github.com/databricks/databricks-sdk-go"
)

func main() {
	databricks.WithProduct("deco", "0.0.1")
	root.Execute()
}
