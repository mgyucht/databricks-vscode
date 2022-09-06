package cleanup

import (
	"deco/cmd/env"
	"deco/testenv"
	"fmt"
	"log"
	"strings"

	"github.com/databricks/databricks-sdk-go/service/scim"
	"github.com/databricks/databricks-sdk-go/service/workspace"
	"github.com/databricks/databricks-sdk-go/workspaces"
	"github.com/spf13/cobra"
)

var cleanupCmd = &cobra.Command{
	Use:   "cleanup",
	Short: "Cleans up testing environment",
	RunE: func(cmd *cobra.Command, args []string) error {
		if env.Name == "" {
			return fmt.Errorf("no environment given")
		}
		cfg, err := testenv.NewConfigFor(cmd.Context(), env.Name)
		if err != nil {
			return err
		}
		if cfg.IsAccountsClient() {
			return fmt.Errorf("currently only workspace client supported")
		}
		ws := workspaces.New(cfg)
		users, err := ws.Users.ListUsers(cmd.Context(), scim.ListUsersRequest{})
		if err != nil {
			return err
		}
		log.Printf("[INFO] Cleaning up users")
		for _, u := range users.Resources {
			email := u.Emails[0].Value
			if !strings.ContainsRune(email, '@') {
				// this is SPN
				continue
			}
			if strings.HasSuffix(email, "@databricks.com") {
				// valid databricks email
				continue
			}
			err = ws.Users.DeleteUserById(cmd.Context(), u.Id)
			if err != nil {
				return err
			}
			log.Printf("[INFO] Removing leftover from tests %s (%s)",
				email, u.DisplayName)
		}
		// it's a workspace client
		folders, err := ws.Workspace.List(cmd.Context(), workspace.ListRequest{
			Path: "/Users",
		})
		if err != nil {
			return err
		}
		for _, v := range folders.Objects {
			if strings.Contains(v.Path, "@databricks.com") {
				continue
			}
			err = ws.Workspace.Delete(cmd.Context(), workspace.DeleteRequest{
				Path:      v.Path,
				Recursive: true,
			})
			if err != nil {
				return err
			}
			log.Printf("[INFO] Removing notebook folder leftover: %s\n", v.Path)
		}
		log.Printf("[INFO] Done.")
		return nil
	},
}

func init() {
	env.EnvCmd.AddCommand(cleanupCmd)
}
