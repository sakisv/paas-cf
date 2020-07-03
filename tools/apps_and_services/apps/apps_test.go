package apps_test

import (
	"github.com/alphagov/paas-cf/tools/apps_and_services/apps"
	"github.com/alphagov/paas-cf/tools/apps_and_services/apps/stubs"
	. "github.com/onsi/ginkgo"
	. "github.com/onsi/gomega"
)

var _ = Describe("Apps", func() {
	Context("with 'normal' urgency", func() {
		It("gets the right number of apps", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			apps.FetchData(&cfFake, "prod")
			Expect(cfFake.ListAppsCallCount()).To(Equal(3))
		})

		It("extracts the username of each space developer in each space", func() {
			_, cfFake := stubs.CreateFakeWithStubData()

			apps := apps.FetchData(&cfFake, "prod")
			Expect(len(apps)).To(Equal(3))
			for _, item := range apps {
				Expect(item.AppName).ToNot(BeNil())
				Expect(item.AppID).ToNot(BeNil())
				Expect(item.Bindings).ToNot(BeNil())
				Expect(item.Region).ToNot(BeNil())
			}
		})
	})
})
