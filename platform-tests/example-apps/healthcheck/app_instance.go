package main

import (
	"encoding/json"
	"net/http"
	"os"
)

func instanceHandler(writer http.ResponseWriter, request *http.Request) {
	cfInstanceIp := os.Getenv("CF_INSTANCE_IP")
	cfAppIndex := os.Getenv("CF_INSTANCE_INDEX")

	output := map[string]string{
		"ip":    cfInstanceIp,
		"index": cfAppIndex,
	}

	outBytes, err := json.Marshal(output)

	if err != nil {
		request.Response.StatusCode = http.StatusInternalServerError
		writer.Write([]byte(err.Error()))
		return
	}

	writer.Write(outBytes)
}
