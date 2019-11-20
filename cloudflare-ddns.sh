#!/usr/bin/env sh
API_URL="https://api.cloudflare.com/client/v4"

command -v jq > /dev/null 2>&1 || { echo 'Command line utility jq not available'; exit 1; }
command -v curl > /dev/null 2>&1 || { echo 'Command line utility curl not available'; exit 1; }

function update_record(){
  token=$1
  zone=$2
  record=$3
  record_type=$4
  record_name=$5
  record_content=$6
  curl -s -X PUT "$API_URL/zones/$zone/dns_records/$record" -H "Authorization: Bearer $token" -H "Content-Type:application/json" --data "{\"type\": \"$record_type\", \"name\": \"$record_name\", \"content\": \"$record_content\", \"ttl\": 120}"  | jq -j ".success"
}

function get_record_id(){
  token=$1
  zone=$2
  record_type=$3
  record_name=$4
  curl -s -X GET "$API_URL/zones/$zone/dns_records?type=$record_type&name=$record_name&match=all&page=1&per_page=1" -H "Authorization: Bearer $token" -H "Content-Type:application/json" | jq -j ".result[0] | .id"
}

function get_zone_id(){
  token=$1
  zone=$2
  curl -s -X GET "$API_URL/zones" -H "Content-Type: application/json" -H "Authorization: Bearer $token" | jq -j ".result[] | select(.name==\"$zone\") | .id"
}

type 'write_log' 2> /dev/null | grep -q 'function' || function write_log(){ echo $2; };

[ -z "$domain" ]   && { write_log 3 "Service section not configured correctly! Missing 'domain' which is the zone name"; exit 1; }
[ -z "$password" ] && { write_log 3 "Service section not configured correctly! Missing 'password' which is the token"; exit 1; }

CF_DNS_ZONE_NAME=$(echo $domain | cut -d'.' -f2-)
CF_DNS_API_TOKEN=$password
CF_DNS_RECORD_NAME=$(echo $domain | cut -d'.' -f1)
CF_DNS_NEW_IP=$__IP

write_log 7 "Zone name: $CF_DNS_ZONE_NAME";
write_log 7 "Record name: $CF_DNS_RECORD_NAME";
write_log 7 "New IP: $CF_DNS_NEW_IP";

CF_DNS_ZONE_ID=$(get_zone_id $CF_DNS_API_TOKEN $CF_DNS_ZONE_NAME) || { write_log 3 'Failed to get the zone id'; exit 1; }
write_log 7 "Found Zone ID: $CF_DNS_ZONE_ID"
CF_DNS_RECORD_ID=$(get_record_id $CF_DNS_API_TOKEN $CF_DNS_ZONE_ID 'A' "$CF_DNS_RECORD_NAME.$CF_DNS_ZONE_NAME") || { write_log 3 'Failed to get the record id'; exit 1; }
write_log 7 "Found Record ID: $CF_DNS_RECORD_ID"
CF_DNS_UPDATE_RESULT=$(update_record $CF_DNS_API_TOKEN $CF_DNS_ZONE_ID $CF_DNS_RECORD_ID 'A' "$CF_DNS_RECORD_NAME.$CF_DNS_ZONE_NAME" $CF_DNS_NEW_IP) || { write_log 3 'Failed to update the record'; exit 1; }

[ $CF_DNS_UPDATE_RESULT = "true" ] || { write_log 3 'Failed to update the record'; exit 1;}
write_log 7 'Record updated'

exit 0
