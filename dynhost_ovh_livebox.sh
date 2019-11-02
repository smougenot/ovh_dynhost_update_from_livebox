#! /bin/bash
#
# Livebox to OVH DynHost
#
# -------------------------------
# Uses Livebox rest api to query for public IP
# Updates (if required) the DynHost at OVH
# Mainly inspired by DynHost script given by OVH
# This script uses 
# - curl to get the public IP and 
# - dig to get the current IP for the dynhost and
# - wget to push new IP
#
# Config :
# Uses a file (if it exists) with same name but extension .conf
# Or direct environment variables
# 
# Required
# - DYNHOST  : DynHost name on OVH
# - LOGIN    : DynHost credential 
# - PASSWORD : DynHost credential 
# 
# Optionals
# - LIVEBOX  : the host name of the livebox seen by the macine running the script (default: livebox)
# -------------------------------

# set -o errexit    # always exit on error
set -o pipefail   # honor exit codes when piping
set -o nounset  # fail on unset variables

currentdir=$(cd -P -- "$(dirname -- "$BASH_SOURCE[0]")" && pwd -P)
currentfile="${0##*/}"

# dns subdomain to update
DYNHOST="${DYNHOST:-}"
# OVH dyndns credentials
LOGIN="${LOGIN:-}"
PASSWORD="${PASSWORD:-}"
LOG_PATH="${LOG_PATH:-/tmp}"
# Livebox host (to access rest API on the box)
LIVEBOX='livebox'

# -------------------------------
# Tooling
# -------------------------------

logTimestamp() {
  echo "$(date +%Y%m%d-%T)"
}

# log message
# $* message
log() {
  echo -e "$(logTimestamp) $@"
}

# Error message plus exit
# $* message
fail() {
  >&2 echo -e "$(logTimestamp) $@"
  exit 1
}

# -------------------------------
# Config
# -------------------------------

# Source config file to get current values for parameters
CONFIG_FILE="${currentdir}/${currentfile%%.*}.conf"
if [ -r "${CONFIG_FILE}" ]; then 
  log "Loading config file ${CONFIG_FILE}"
  source "${CONFIG_FILE}"
else
  log "No config file ${CONFIG_FILE}"
fi

[ -z "${DYNHOST}" ] && fail "Config error : missing DYNHOST"

# prepare tmp file
TMPFILE=$(mktemp -t dynhost_update_XXXXXX.log )

# Cleanup at end of script execution
cleanup () {
  [ -z ${TMPFILE} ] || rm -f ${TMPFILE}
}
trap cleanup EXIT

# -------------------------------
# Update DynDns
# -------------------------------

log '----------------------------------'
log "DynHost update for ${DYNHOST}"

IP=$(curl -s -X POST -H "Content-Type: application/json" -d '{"parameters":{}}'  \
        http://${LIVEBOX:-livebox}/sysbus/NMC:getWANStatus \
        | sed -e 's/.*"IPAddress":"\(.*\)","Remo.*/\1/g')
# IPv6=$(curl -s -X POST -H "Content-Type: application/json" -d '{"parameters":{}}' \
#         http://${LIVEBOX:-livebox}/sysbus/NMC:getWANStatus \
#         | sed -e 's/.*"IPv6Address":"\(.*\)","IPv6D.*/\1/g')

# Get NS entry for authority on the DYNHOST
NS_ENTRY=''
dig +short "${DYNHOST#*.}" NS > "${TMPFILE}"
if [ $(wc -l "${TMPFILE}") -gt 1 ]; then
  NS_ENTRY="$(head -1 "${TMPFILE}")"
  log "Found NS for ${DYNHOST} : ${NS_ENTRY}"
else
  NS_ENTRY="${LIVEBOX}"
  log "No NS found for ${DYNHOST}, using : ${NS_ENTRY}"
fi

# get current IP of DynHost
OLDIP=$(dig +short @${NS_ENTRY} ${DYNHOST})

# Can not get current ip
[[ -z "{IP}" ]] && fail "Could not find ip using livebox API"

log "Old IP: ${OLDIP}"
log "New IP: ${IP}"

# Nothing to do
if [[ "${OLDIP}" == "${IP}" ]]; then
  log "IP ${DYNHOST} ${OLDIP} is identical to WAN ${IP}! No update required."
  exit 0
fi

# At this point DNS entry needs update
log 'Try to update!'

wget -q -O $TMPFILE \
    "http://www.ovh.com/nic/update?system=dyndns&hostname=${DYNHOST}&myip=${IP}" \
    --user="${LOGIN}" --password="${PASSWORD}"

RESULT=$(cat $TMPFILE)
log "Result: $RESULT"
if [[ $RESULT =~ ^(good|nochg).* ]]; then
  log ----------------------------------
  log "Update sucessful"
fi
rm $TMPFILE
