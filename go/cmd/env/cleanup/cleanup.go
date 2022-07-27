package cleanup

import (
	"deco/cmd/env"
	"deco/testenv"
	"fmt"
	"log"
	"strings"

	"github.com/databricks/terraform-provider-databricks/scim"
	"github.com/databricks/terraform-provider-databricks/workspace"
	"github.com/spf13/cobra"
)

var cleanupCmd = &cobra.Command{
	Use:   "cleanup",
	Short: "Cleans up testing environment",
	RunE: func(cmd *cobra.Command, args []string) error {
		if env.Name == "" {
			return fmt.Errorf("no environment given")
		}
		client, err := testenv.NewClientFor(cmd.Context(), env.Name)
		if err != nil {
			return err
		}
		usersApi := scim.NewUsersAPI(cmd.Context(), client)
		users, err := usersApi.Filter("")
		if err != nil {
			return err
		}
		log.Printf("[INFO] Cleaning up users")
		for _, u := range users {
			email := u.Emails[0].Value
			if !strings.ContainsRune(email, '@') {
				// this is SPN
				continue
			}
			if strings.HasSuffix(email, "@databricks.com") {
				// valid databricks email
				continue
			}
			err = usersApi.Delete(u.ID)
			if err != nil {
				return err
			}
			log.Printf("[INFO] Removing leftover from tests %s (%s)",
				email, u.DisplayName)
		}
		if client.AccountID == "" {
			// it's a workspace client
			wsApi := workspace.NewNotebooksAPI(cmd.Context(), client)
			folders, err := wsApi.List("/Users", false)
			if err != nil {
				return err
			}
			for _, v := range folders {
				if strings.Contains(v.Path, "@databricks.com") {
					continue
				}
				err = wsApi.Delete(v.Path, true)
				if err != nil {
					return err
				}
				log.Printf("[INFO] Removing notebook folder leftover: %s\n", v.Path)
			}
		}
		log.Printf("[INFO] Done.")
		return nil
	},
}

func init() {
	env.EnvCmd.AddCommand(cleanupCmd)
}
