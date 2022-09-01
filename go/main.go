package main

import (
	_ "deco/cmd/env"
	_ "deco/cmd/env/api"
	_ "deco/cmd/env/cleanup"
	_ "deco/cmd/env/export"
	_ "deco/cmd/env/list"
	_ "deco/cmd/env/shell"
	_ "deco/cmd/env/test"
	_ "deco/cmd/env/test/all"
	_ "deco/cmd/env/test/debug"
	_ "deco/cmd/gh"
	_ "deco/cmd/gh/checkoutpr"
	_ "deco/cmd/gh/releasenotes"
	_ "deco/cmd/gh/updateprs"
	"deco/cmd/root"
	_ "deco/cmd/tf"
	_ "deco/cmd/tf/cov"
	_ "deco/cmd/version"

	"github.com/databricks/databricks-sdk-go/databricks"
)

func main() {
	databricks.WithProduct("deco", "0.0.1")
	root.Execute()
}
