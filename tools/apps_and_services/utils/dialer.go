package utils

import "github.com/cloudfoundry-community/go-cfclient"

func Dialer(apiEndpoint string, apiToken string) (dialer *cfclient.Client, err error) {
	client, err := cfclient.NewClient(&cfclient.Config{
		ApiAddress: apiEndpoint,
		Token:      apiToken,
	})
	return client, err

}
