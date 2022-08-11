# Developer Ecosystem Tooling

## Create a local snapshot of `deco` CLI

First install

1. `brew install golang goreleaser`
2. Make sure to have `ext/terraform-provider-databricks` symlink
3. `goreleaser snapshot --rm-dist`
4. Symlink `dist/deco_darwin_amd64_v1/deco` to any directory in your `$PATH`
5. `deco completion zsh > /usr/local/share/zsh/site-functions/_deco` to enable tab-completion
6. restart terminal for `zsh` to load new changes

Once first install is done, you'll need to repeat only the step 3.