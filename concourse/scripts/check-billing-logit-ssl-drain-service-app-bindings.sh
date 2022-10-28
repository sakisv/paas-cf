#!/usr/bin/env bash

APP1='paas-billing-api'
APP2='paas-billing-collector'

APP1_GUID=$(cf curl "/v3/apps?names=${APP1}" | jq -r '.resources[].guid')
APP2_GUID=$(cf curl "/v3/apps?names=${APP2}" | jq -r '.resources[].guid')

SI_GUID=$(cf curl /v3/service_instances | jq -r '.resources[]|select(.name=="billing-logit-ssl-drain").guid')

SCB=$(cf curl "/v3/service_credential_bindings?service_instance_guids=${SI_GUID}")

SCB_COUNT=$(echo "$SCB" | jq -r '.resources|length')
if [ "$SCB_COUNT" != "2" ]; then
  echo "ERROR: expecting 2 service credential bindings. got: $SCB_COUNT"
  exit 1
fi

BIND1=$(jq -r '.resources[0].relationships.app.data.guid' <<< "${SCB}")
STATE1=$(jq -r '.resources[0].last_operation.state' <<< "${SCB}")
TYPE1=$(jq -r '.resources[0].last_operation.type' <<< "${SCB}")
BIND2=$(jq -r '.resources[1].relationships.app.data.guid' <<< "${SCB}")
STATE2=$(jq -r '.resources[1].last_operation.state' <<< "${SCB}")
TYPE2=$(jq -r '.resources[1].last_operation.type' <<< "${SCB}")

if ! [[ "${BIND1}" = "${APP1_GUID}" && "${BIND2}" = "${APP2_GUID}" || "${BIND1}" = "${APP2_GUID}" && "${BIND2}" = "${APP1_GUID}" ]]; then
  echo "ERROR: could not match app guis to service binds"
  exit 1
fi

if ! [[ "$STATE1" = "succeeded" && "$TYPE1" = "create" && "$STATE2" = "succeeded" && "$TYPE2" = "create" ]]; then
  echo "ERROR: one or more bad bind states/types"
  exit 1
fi

echo "Checked binding of billing-logit-ssl-drain service to billing apps..."
