package cleanup

import (
	"deco/cmd/env"
	"deco/testenv"
	"log"
	"strings"

	"github.com/databricks/terraform-provider-databricks/scim"
	"github.com/spf13/cobra"
)

var cleanupCmd = &cobra.Command{
	Use:   "cleanup env-name",
	Short: "Cleans up testing environment",
	Args:  cobra.ExactArgs(1),
	RunE: func(cmd *cobra.Command, args []string) error {
		client, err := testenv.NewClientFor(cmd.Context(), args[0])
		if err != nil {
			return err
		}
		usersApi := scim.NewUsersAPI(cmd.Context(), client)
		users, err := usersApi.Filter("")
		if err != nil {
			return err
		}
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
		log.Printf("[INFO] Done.")
		return nil
	},
}

func init() {
	env.EnvCmd.AddCommand(cleanupCmd)
}
