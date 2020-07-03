package apps

import (
	"github.com/cloudfoundry-community/go-cfclient"
)

// This interface is extracted as a subset of
// methods on the `Client` struct of
// github.com/cloudfoundry-community/go-cfclent.
// We use it so that we can mock the CF client
// calls elsewhere.
type Client interface {
	ListApps() ([]cfclient.App, error)
	GetAppByGuidNoInlineCall(guid string) (cfclient.App, error)
	GetSpaceByGuid(spaceGUID string) (cfclient.Space, error)
	GetOrgByGuid(guid string) (cfclient.Org, error)
}

type App interface {
	Summary() ([]cfclient.AppSummary, error)
}
