module deco

go 1.18

require (
	github.com/Azure/azure-sdk-for-go/sdk/azidentity v1.1.0
	github.com/databricks/databricks-sdk-go v0.0.0
	github.com/hashicorp/go-version v1.6.0
	github.com/hashicorp/hc-install v0.4.0
	github.com/hashicorp/hcl/v2 v2.13.0
	github.com/hashicorp/terraform-exec v0.17.2
	github.com/spf13/cobra v1.4.0
	github.com/stretchr/testify v1.8.1
	golang.org/x/exp v0.0.0-20220722155223-a9213eeb770e
)

require (
	cloud.google.com/go/compute/metadata v0.2.1 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/azcore v1.1.1 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/internal v1.0.0 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/keyvault/internal v0.5.0 // indirect
	github.com/AzureAD/microsoft-authentication-library-for-go v0.5.1 // indirect
	github.com/apex/log v1.9.0 // indirect
	github.com/c4milo/unpackit v0.1.0 // indirect
	github.com/chzyer/readline v0.0.0-20180603132655-2972be24d48e // indirect
	github.com/dsnet/compress v0.0.1 // indirect
	github.com/fsnotify/fsnotify v1.4.9 // indirect
	github.com/golang-jwt/jwt v3.2.1+incompatible // indirect
	github.com/google/go-github v17.0.0+incompatible // indirect
	github.com/google/uuid v1.3.0 // indirect
	github.com/gosuri/uilive v0.0.4 // indirect
	github.com/gosuri/uiprogress v0.0.1 // indirect
	github.com/hokaccha/go-prettyjson v0.0.0-20211117102719-0474bc63780f // indirect
	github.com/klauspost/compress v1.4.1 // indirect
	github.com/klauspost/cpuid v1.2.0 // indirect
	github.com/klauspost/pgzip v1.2.5 // indirect
	github.com/kylelemons/godebug v1.1.0 // indirect
	github.com/pkg/browser v0.0.0-20210115035449-ce105d075bb4 // indirect
	github.com/pkg/errors v0.9.1 // indirect
	github.com/sethvargo/go-envconfig v0.6.0 // indirect
	github.com/ulikunitz/xz v0.5.10 // indirect
	gopkg.in/tomb.v1 v1.0.0-20141024135613-dd632973f1e7 // indirect
)

require (
	cloud.google.com/go/compute v1.12.1 // indirect
	github.com/Azure/azure-sdk-for-go/sdk/keyvault/azsecrets v0.8.0
	github.com/TylerBrock/colorjson v0.0.0-20200706003622-8a50f05110d2
	github.com/agext/levenshtein v1.2.2 // indirect
	github.com/apparentlymart/go-textseg/v13 v13.0.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/fatih/color v1.13.0 // indirect
	github.com/golang-jwt/jwt/v4 v4.4.2 // indirect
	github.com/golang/groupcache v0.0.0-20200121045136-8c9f03a8e57e // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/google/go-github/v45 v45.2.0
	github.com/google/go-querystring v1.1.0 // indirect
	github.com/googleapis/enterprise-certificate-proxy v0.2.0 // indirect
	github.com/hashicorp/go-cleanhttp v0.5.2 // indirect
	github.com/hashicorp/terraform-json v0.14.0
	github.com/inconshreveable/mousetrap v1.0.0 // indirect
	github.com/manifoldco/promptui v0.9.0
	github.com/mattn/go-colorable v0.1.12 // indirect
	github.com/mattn/go-isatty v0.0.14 // indirect
	github.com/mitchellh/go-wordwrap v1.0.0 // indirect
	github.com/nxadm/tail v1.4.8
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/sethvargo/go-githubactions v1.0.0
	github.com/spf13/pflag v1.0.5 // indirect
	github.com/tj/go-update v2.2.4+incompatible
	github.com/zclconf/go-cty v1.11.0
	go.opencensus.io v0.24.0 // indirect
	golang.org/x/crypto v0.0.0-20220722155217-630584e8d5aa // indirect
	golang.org/x/mod v0.6.0-dev.0.20220419223038-86c51ed26bb4 // indirect
	golang.org/x/net v0.0.0-20221014081412-f15817d10f9b // indirect
	golang.org/x/oauth2 v0.0.0-20221014153046-6fdb5e3db783
	golang.org/x/sys v0.0.0-20220728004956-3c1f35247d10 // indirect
	golang.org/x/text v0.4.0 // indirect
	golang.org/x/time v0.0.0-20210723032227-1f47c861a9ac // indirect
	google.golang.org/api v0.103.0 // indirect
	google.golang.org/appengine v1.6.7 // indirect
	google.golang.org/genproto v0.0.0-20221027153422-115e99e71e1c // indirect
	google.golang.org/grpc v1.50.1 // indirect
	google.golang.org/protobuf v1.28.1 // indirect
	gopkg.in/ini.v1 v1.67.0
	gopkg.in/yaml.v3 v3.0.1
)

replace github.com/databricks/databricks-sdk-go v0.0.0 => ../ext/databricks-sdk-go
