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
source ${commons}/gcloud/functions/substitute.sh

# requirements
checkProgs kubectl
checkDir yaml

function help(){
        echo "Basic Usage: $0 -d domainname"
        exit 1
}

# enable some options
while getopts 'd:' opt; do
        case ${opt} in
                d) domain="$OPTARG" ;;
                *) help
        esac
done

kubectl apply -f yaml/

# this will substitute the correct domain in ingress.yaml
if [ ${domain} ]; then
        substitute ingress DOMAINNAME ${domain}
        kubectl apply -f yaml/substitutions/ingress.yaml.tmp
        rm yaml/substitutions/ingress.yaml.tmp
fi
