#!/usr/bin/env bash

set -e

# set bash commons
if [ "${PWD##*/}" = "ops-gcp-kubernetes" ]; then
	commons="ops-bash-commons"
else
	commons="ops-gcp-kubernetes/ops-bash-commons"
fi

# script dependencies
source ${commons}/functions/checks.sh
source ${commons}/gcloud/functions/debug.sh
source ${commons}/gcloud/functions/getConfig.sh

# gcloud verbosity
debug=false
gcloudDebug

# requirements
checkProgs gcloud

function help(){
        echo "Basic Usage: $0 -c test-cluster -v 1.7.2 -p (PRODUCTION ONLY)"
        exit 1
}

# enable some options
while getopts 'c:v:n:s:b:p' opt; do
        case ${opt} in
                c) cluster="$OPTARG" ;;
                v) version="$OPTARG" ;;
                n) network="$OPTARG" ;;
		s) subnet="$OPTARG" ;;
		b) block="$OPTARG" ;;
                p) prod="true" ;;
                *) help
        esac
done

if [ ! "${cluster}" ]
then
        help
fi

# check for existing cluster
checkCluster=$(gcloud container clusters list --filter=name:${cluster} --format="value(selfLink.basename())")
if [ "${checkCluster}" != "${cluster}" ]; then
        if [ ${prod} ]; then
                ${gcloud} beta container clusters create ${cluster} --network=${network} --subnetwork=${subnet} --cluster-ipv4-cidr=${block} --cluster-version=${version} --machine-type=n1-standard-4 \
                --scopes="https://www.googleapis.com/auth/ndev.clouddns.readwrite,cloud-source-repos,storage-rw,https://www.googleapis.com/auth/trace.append" \
                --enable-cloud-monitoring --enable-cloud-logging --enable-autoupgrade --enable-autoscaling --enable-stackdriver-kubernetes --max-nodes=3 --min-nodes=2
        else
                ${gcloud} container clusters create ${cluster} --network=${network} --subnetwork=${subnet} --cluster-ipv4-cidr=${block} --cluster-version=${version} \
                --scopes="https://www.googleapis.com/auth/ndev.clouddns.readwrite,cloud-source-repos,storage-rw"
        fi
        
        ${gcloud} container clusters get-credentials ${cluster}
	
	# create cluster role binding
	kubectl create clusterrolebinding cluster-admin-binding --clusterrole cluster-admin --user $(gcloud config get-value account)

else
        echo "There is already a cluster named: ${cluster}"
        ${gcloud} container clusters get-credentials ${cluster}
fi
