package main

import (
	"deco/ecosystem/golang"
	"flag"
	"fmt"
	"log"
	"os"
)

// Read the JSON output of a `go test` run and reproduce reporting output.
func main() {
	flag.Parse()
	if flag.Arg(0) == "" {
		fmt.Printf("%s: please specify log file\n", os.Args[0])
		os.Exit(1)
	}

	f, err := os.Open(flag.Arg(0))
	if err != nil {
		panic(err)
	}

	defer f.Close()

	ch := golang.ReadTestEvents(f)
	report := golang.CollectTestReport(ch)
	log.Printf("[INFO] %s", report)
}
