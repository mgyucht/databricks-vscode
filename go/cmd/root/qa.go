package root

func Run(args ...string) error {
	RootCmd.SetArgs(args)
	return RootCmd.Execute()
}
