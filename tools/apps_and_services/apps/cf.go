package apps

import (
	"encoding/json"
	"fmt"
	"io/ioutil"
	"net/http"

	"github.com/cloudfoundry-community/go-cfclient"
	"github.com/pkg/errors"
)

// This interface is extracted as a subset of
// methods on the `Client` struct of
// github.com/cloudfoundry-community/go-cfclient.
// We use it so that we can mock the CF client
// calls elsewhere.
type Client interface {
	NewRequest(method, path string) *cfclient.Request
	DoRequest(req *cfclient.Request) (*http.Response, error)
	ListApps() ([]cfclient.App, error)
	GetAppByGuidNoInlineCall(guid string) (cfclient.App, error)
	GetSpaceByGuid(spaceGUID string) (cfclient.Space, error)
	GetOrgByGuid(guid string) (cfclient.Org, error)
}

type App interface {
	Summary() ([]cfclient.AppSummary, error)
}

type ServiceBindings struct {
	Pagination struct {
		Results int `json:"total_results"`
	} `json:"pagination"`
}

func GetBindingsCount(guid string, client Client) (int, error) {
	var serviceBindings ServiceBindings
	requestURL := fmt.Sprintf("/v3/service_bindings?app_guids=%s", guid)
	r := client.NewRequest("GET", requestURL)
	resp, err := client.DoRequest(r)
	if err != nil {
		return 0, errors.Wrap(err, "Error requesting app summary")
	}
	resBody, err := ioutil.ReadAll(resp.Body)
	defer resp.Body.Close()
	if err != nil {
		return 0, errors.Wrap(err, "Error reading app summary body")
	}
	err = json.Unmarshal(resBody, &serviceBindings)
	if err != nil {
		return 0, errors.Wrap(err, "Error unmarshalling app summary")
	}
	return serviceBindings.Pagination.Results, nil
}
