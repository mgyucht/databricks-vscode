package version

import (
	"deco/cmd/root"
	"fmt"
	"log"
	"runtime"
	"runtime/debug"

	"github.com/tj/go-update"
	"github.com/tj/go-update/progress"
	"github.com/tj/go-update/stores/github"

	"github.com/spf13/cobra"
)

var versionCmd = &cobra.Command{
	Use: "version",
	RunE: func(cmd *cobra.Command, args []string) error {
		// https://github.com/tj/go-update
		info, ok := debug.ReadBuildInfo()
		if !ok {
			return fmt.Errorf("no build info")
		}
		for _, s := range info.Settings {
			log.Printf("[INFO][build info] %s: %s", s.Key, s.Value)
		}
		log.Printf("[INFO] version: %s ", info.Main.Version)

		m := &update.Manager{
			Command: "deco",
			Store: &github.Store{
				Owner:   "databricks",
				Repo:    "eng-dev-ecosystem",
				Version: "0.0.1", // todo: make it more dynamic
			},
		}
		releases, err := m.LatestReleases()
		if err != nil {
			return err
		}
		if len(releases) == 0 {
			log.Printf("[INFO] no updates")
			return nil
		}
		log.Printf("[INFO] got update: %v", releases)

		// latest release
		latest := releases[0]

		// find the tarball for this system
		a := latest.FindTarball(runtime.GOOS, runtime.GOARCH)
		if a == nil {
			return fmt.Errorf("no binary for your system")
		}

		// whitespace
		fmt.Println()

		// download tarball to a tmp dir
		tarball, err := a.DownloadProxy(progress.Reader)
		if err != nil {
			return err
		}

		// install it
		if err := m.Install(tarball); err != nil {
			return err
		}

		fmt.Printf("Updated to %s\n", latest.Version)

		return nil
	},
}

func init() {
	root.RootCmd.AddCommand(versionCmd)
}
