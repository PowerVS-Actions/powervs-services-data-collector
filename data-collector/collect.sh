#!/bin/bash

: '
    Copyright (C) 2022 IBM Corporation
    Rafael Sene <rpsene@br.ibm.com> - Initial implementation.
'

# Trap ctrl-c and call ctrl_c()
trap ctrl_c INT

function ctrl_c() {
    echo "Bye!"
    exit 0
}

function check_dependencies() {
    echo "* checking dependencies..."
    DEPENDENCIES=(ibmcloud curl sh wget jq python3)
    check_connectivity
    for i in "${DEPENDENCIES[@]}"
    do
        if ! command -v "$i" &> /dev/null; then
            echo "$i could not be found, exiting!"
            exit 1
        fi
    done
}

function check_connectivity() {
    echo "* checking internet connectivity..."
    if ! curl --output /dev/null --silent --head --fail http://cloud.ibm.com; then
        echo "ERROR: please, check your internet connection."
        exit 1
    fi
}

function authenticate() {
    echo "* authenticating..."
    local APY_KEY="$1"

    if [ -z "$APY_KEY" ]; then
        echo "API KEY was not set."
        exit
    fi
    ibmcloud update -f > /dev/null 2>&1
    ibmcloud plugin update --all > /dev/null 2>&1
    ibmcloud login --no-region --apikey "$APY_KEY" > /dev/null 2>&1
}

function get_crns(){

    echo "* getting all CRNs..."
    local TODAY
    TODAY=$(date '+%Y%m%d')
    local IBMCLOUD_ID="$1"

	rm -f "$(pwd)/$IBMCLOUD_ID/crns-$TODAY-$IBMCLOUD_ID"
    rm -f "$(pwd)/$IBMCLOUD_ID/pvs-services-$TODAY-$IBMCLOUD_ID"

	ibmcloud pi service-list --json | jq -r '.[] | "\(.CRN),\(.Name)"' >> "$(pwd)/$IBMCLOUD_ID/crns-$TODAY-$IBMCLOUD_ID"

	while read -r line; do
        local CRN
        CRN=$(echo "$line" | awk -F ',' '{print $1}')
        local POWERVS_NAME
        POWERVS_NAME=$(echo "$line" | awk -F ',' '{print $2}')
        local POWERVS_ZONE
        POWERVS_ZONE=$(echo "$line" | awk -F ':' '{print $6}')
        local POWERVS_ID
        POWERVS_ID=$(echo "$line" | awk -F ':' '{print $8}')
        local IBMCLOUD_ID="$1"
        local IBMCLOUD_NAME="$2"
        echo "$IBMCLOUD_ID,$IBMCLOUD_NAME,$POWERVS_ID,$POWERVS_NAME,$POWERVS_ZONE,$CRN" >> \
        "$(pwd)/$IBMCLOUD_ID/$IBMCLOUD_ID-services"
	done < "$(pwd)/$IBMCLOUD_ID/crns-$TODAY-$IBMCLOUD_ID"
}

function run (){

    if [ -z "$IBMCLOUD_ID" ]; then
        echo "ERROR: please, set your IBM Cloud ID."
        exit 1
    fi

    if [ -z "$IBMCLOUD_NAME" ]; then
        echo "ERROR: please, set your IBM Cloud name."
        exit 1
    fi

    if [ -z "$API_KEY" ]; then
        echo
        echo "ERROR: please, set your IBM Cloud API Key."
        echo "		 e.g ./vms-age.sh API_KEY"
        echo
        exit 1
    else
        check_dependencies
        authenticate "$API_KEY"

        if [ -d "$IBMCLOUD_ID" ]; then
            rm -rf "${IBMCLOUD_ID:?}"
            mkdir -p "$IBMCLOUD_ID"
        else
            mkdir -p "$IBMCLOUD_ID"
        fi
        get_crns "$IBMCLOUD_ID" "$IBMCLOUD_NAME"
    fi
}

run "$@"