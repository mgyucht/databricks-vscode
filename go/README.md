# Developer Ecosystem Tooling

## Create a local snapshot of `deco` CLI

First install

1. Make sure to have `ext/terraform-provider-databricks` symlink
2. `brew install golang goreleaser`
3. `cd go && goreleaser release --snapshot --rm-dist`
4. `ln -s $PWD/dist/deco_darwin_amd64_v1/deco /usr/local/bin/deco`
5. `deco completion zsh > /usr/local/share/zsh/site-functions/_deco` to enable tab-completion
6. restart terminal for `zsh` to load new changes

Once first install is done, you'll need to repeat only the step 3.