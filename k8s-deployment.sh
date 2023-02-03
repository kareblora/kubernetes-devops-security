#!/bin/bash

export KUBECONFIG=/etc/kubernetes/admin.conf
sudo sed -i "s#replace#${imageName}#g" k8s_deployment_service.yaml
sudo kubectl -n default get deployment ${deploymentName} > /dev/null

# if [[ $? -ne 0 ]]; then
#     echo "Deployment ${deploymentName} doesn't exist"
#     kubectl apply -f k8s_deployment_service.yaml
# else
#     echo "Deployment ${deploymentName} exist"
#     echo "Image Name - ${imageName} exist"
#     kubectl -n default set image deploy ${deploymentName} ${containerName}=${imageName} --record=true
# fi;

sudo kubectl apply -f k8s_deployment_service.yaml