package apps

import (
	"github.com/alphagov/paas-cf/tools/apps_and_services/utils"
	"github.com/cloudfoundry-community/go-cfclient"
	"github.com/xenolf/lego/log"
	"os"
	"time"
)

type AppDetails struct {
	Org			string 	`csv:"org"`
	SpaceName	string 	`csv:"space_name"`
	AppName    	string 	`csv:"app"`
	AppID  		string 	`csv:"app_id"`
	Bindings   	int 	`csv:"binding_count"`
	Region 		string 	`csv:"region"`
}

func FetchData(client Client, region string) []AppDetails {

	apps, err := client.ListApps()

	if err != nil {
		log.Fatal(err)
		return nil
	}

	var appdata []cfclient.App
	data := []AppDetails{}

	status := utils.NewStatus(os.Stderr, false)
	for _, app := range apps {
		if err != nil {
			log.Fatal(err)
			return nil
		}
		status.Text(app.Name)
		appdata = append(appdata, app)
		appsummary , err := app.Summary()
		if err != nil {
			log.Fatal(err)
			return nil
		}
		appData , err:= client.GetAppByGuidNoInlineCall(app.Guid)
		if err != nil {
			log.Fatal(err)
			return nil
		}

		spaceData , err:= client.GetSpaceByGuid(appData.SpaceGuid)
		if err != nil {
			log.Fatal(err)
			return nil
		}

		orgData , err:= client.GetOrgByGuid(spaceData.OrganizationGuid)
		if err != nil {
			log.Fatal(err)
			return nil
		}

		record := AppDetails{Org: orgData.Name , SpaceName: spaceData.Name, AppName: app.Name, AppID: app.Guid, Bindings: appsummary.ServiceCount, Region: region}
		data = append(data, record)

		time.Sleep(5000)

		status.Done()
	}

	return data
}
