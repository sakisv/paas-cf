package main

import (
	"encoding/json"
	"fmt"
	"github.com/alphagov/paas-cf/tools/apps_and_services/apps"
	"github.com/alphagov/paas-cf/tools/apps_and_services/utils"
	"github.com/jszwec/csvutil"
	"github.com/xenolf/lego/log"
	"gopkg.in/alecthomas/kingpin.v2"
	"os"
)

var (
	apiEndpoint   = kingpin.Flag("api-endpoint", "API endpoint").Default("").Envar("API_ENDPOINT").String()
	apiToken      = kingpin.Flag("api-token", "CF OAuth API token").Default("").Envar("API_TOKEN").String()
	region        = kingpin.Flag("region-info", "PaaS region targeted").Default("").Envar("MAKEFILE_ENV_TARGET").String()
	format        = kingpin.Flag("format", "Output format. Defaults to CSV. Options: csv, json").Default("csv").Envar("FORMAT").String()
)

var (
	FORMAT_CSV    = "csv"
	FORMAT_JSON   = "json"
	VALID_FORMATS = []string{FORMAT_CSV, FORMAT_JSON}
)

func main() {
	kingpin.Parse()

	if !apiTokenPresent(apiToken) {
		log.Fatal("no API token provided")
		os.Exit(1)
	}

	if !validFormat(format) {
		log.Fatalf("Invalid format '%s'", format)
	}

	ClientConnection, err := utils.Dialer(*apiEndpoint, *apiToken)

	if err != nil {
		log.Fatal(err)
		os.Exit(1)
	}

	appinfo := apps.FetchData(ClientConnection, location(*region))

	if *format == FORMAT_CSV {
		outputCsv(appinfo)
	}

	if *format == FORMAT_JSON {
		outputJson(appinfo)
	}
}

func outputJson(addresses []apps.AppDetails) {
	b, err := json.Marshal(addresses)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	fmt.Println(string(b))
}

func outputCsv(addresses []apps.AppDetails) {
	b, err := csvutil.Marshal(addresses)
	if err != nil {
		fmt.Println("error:", err)
		return
	}
	fmt.Println(string(b))
}

func validFormat(format *string) bool {
	if format == nil {
		return false
	}

	for _, valid := range VALID_FORMATS {
		if valid == *format {
			return true
		}
	}

	return false
}

func location(location string) string {
	switch location {
	case "prod":
		foundry := "Ireland"
		return foundry
	case "prod-lon":
		foundry := "London"
		return foundry
	default:
		foundry := "Not Prod"
		return foundry
	}
}

func apiEndpointPresent(apiEndpoint *string) bool {
	if apiEndpoint == nil || *apiEndpoint == "" {
		return false
	}

	return true
}

func apiTokenPresent(apiToken *string) bool {
	if apiToken == nil || *apiToken == "" {
		return false
	}

	return true
}
