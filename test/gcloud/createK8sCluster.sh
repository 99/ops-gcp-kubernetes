#!/usr/bin/env bash

# set bash-commons
commons=ops-bash-commons

# script dependencies
source ${commons}/functions/colors.sh
source ${commons}/functions/testing.sh
source ${commons}/gcloud/functions/setConfig.sh

# set test environment
cleanup=true
testName=common-test
project=ops-iac-sb
zone=us-east4-a
cluster=${testName}-cluster

# depends
cmd="setConfig -p ${project} -z ${zone}"
echoBlue "Running dependency: ${cmd}"
${cmd}
depResults

# failure testing createK8sCluster.sh
cmd="gcloud/createK8sCluster.sh -p"
echoYellow "Running failure test on: ${cmd}"
${cmd} 2>&1
failResults

cmd="gcloud/createK8sCluster.sh -x ${cluster}"
echoYellow "Running failure test on: ${cmd}"
${cmd} 2>&1
failResults


# test createK8sCluster.sh
cmd="gcloud/createK8sCluster.sh -c ${cluster}"
echoCyan "Running test on: ${cmd}"
${cmd} 2>&1
results

# test apply.sh
cmd="kubectl/apply.sh"
echoCyan "Running test on: ${cmd}"
${cmd} 2>&1
results

# test createK8sCluster.sh (Note this is testing for an already existing cluster)
cmd="gcloud/createK8sCluster.sh -c ${cluster}"
echoCyan "Running test on: ${cmd}"
${cmd} 2>&1
results

# cleanup
if [ "${cleanup}" = true ]; then
        # gcloud verbosity
        gcloudDebug=false
        if [ "${gcloudDebug}" = true ]; then
                export gcloud="gcloud -q --verbosity=debug"
        else
                export gcloud="gcloud -q --verbosity=error --no-user-output-enabled"
        fi
        
        cmd="${gcloud} container clusters delete ${cluster}"
        echoBlue "Running cleanup command: ${cmd}"
        ${cmd} 2>&1
fi

# fail overall script if any of the individual results fail
if [ "${fail}" = true ]; then
        exit 1
fi
