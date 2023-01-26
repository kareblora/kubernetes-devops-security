#!/bin/bash

sleep 60s

if [[ $(kubectl -n default rollout status deploy ${deploymentName} --timeout 5s) != *"successfully roled out"* ]]; then
    echo "Deployment ${deploymentName} Rollout has Failed"
    kubectl -n default rollout undo deploy ${deploymentName}
    exit 1;
else
    echo "Deployment ${deploymentName} Rollout is Successful"
fi;