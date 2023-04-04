#!/usr/bin/env bash

# Store Client ID and Client Secret in variables
clientId="$1"
clientSecret="$2"

# Retrieve the OAuth2 JSON response from Sophos Central
oauthJson=$(curl --max-time 60 -s -X POST -H "Content-Type: application/x-www-form-urlencoded" \
   -d "grant_type=client_credentials&client_id=${clientId}&client_secret=${clientSecret}&scope=token" --compressed https://id.sophos.com/api/v2/oauth2/token)
accessToken=$(echo "$oauthJson" | jq ".access_token" | sed 's/["]*//g')

whoamiJson=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accessToken}" --compressed https://api.central.sophos.com/whoami/v1)
tenantId=$(echo "$whoamiJson" | jq ".id" | sed 's/["]*//g')
dataRegion=$(echo "$whoamiJson" | jq ".apiHosts.dataRegion" | sed 's/["]*//g')

getEndpoints=$(curl --max-time 60 -s -X GET -H "Authorization: Bearer ${accessToken}" -H "X-Tenant-ID: ${tenantId}" -H "Accept: application/json" --compressed ${dataRegion}/endpoint/v1/endpoints)

echo ${getEndpoints//\\/\\\\} | jq -c '.items[]' | while read endpoint; do
    echo sophos.central.endpoint,host=$(echo ${endpoint} | jq '.hostname' | sed 's/["]*//g'),id=$(echo ${endpoint} | jq '.id' | sed 's/["]*//g') healthOverall=$(echo ${endpoint} | jq '.health.overall' | sed 's/["]*//g;s/good/0/g;s/suspicious/1/g;s/bad/2/g;s/unknown/3/g')i,threatsStatus=$(echo ${endpoint} | jq '.health.threats.status' | sed 's/["]*//g;s/good/0/g;s/suspicious/1/g;s/bad/2/g;s/unknown/3/g')i,servicesStatus=$(echo ${endpoint} | jq '.health.services.status' | sed 's/["]*//g;s/good/0/g;s/suspicious/1/g;s/bad/2/g;s/unknown/3/g')i,osIsServer=$(echo ${endpoint} | jq '.os.isServer' | sed 's/["]*//g'),osBuild=$(echo ${endpoint} | jq '.os.build' | sed 's/["]*//g'),tamperProtectionEnabled=$(echo ${endpoint} | jq '.tamperProtectionEnabled' | sed 's/["]*//g'),osName=\"$(echo ${endpoint} | jq '.os.name' | sed 's/[\"]*//g')\",lastSeenAt=\"$(echo ${endpoint} | jq '.lastSeenAt' | sed 's/[\"]*//g')\",ipv4Addresses=\"$(echo ${endpoint} | jq -r '.ipv4Addresses[]' 2> /dev/null | paste -sd ',')\"
done
