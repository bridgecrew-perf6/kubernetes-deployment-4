#!/bin/bash

#This script is to display the ip and port where the website is up and running!!!

#Kubernetes service name - "web"

check="web"

nodeport=$(kubectl get svc | grep web | awk '{print $5}' | cut -d ':' -f 2 | sed 's#/TCP##g')

for i in $(kubectl get svc | cut -d ' ' -f 1)
do
        if [ $i == $check ]; then
                echo "Try "$(curl -s ifconfig.me)":"$nodeport" ip & port to see the website running on the Kubernetes Cluster"
        fi

done
