#!/bin/bash
USERNAME=$(kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath='{.data.admin-user}' | base64 -d)
PASSWORD=$(kubectl get secret --namespace monitoring prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d)
echo "user: ${USERNAME}"
echo "pass: ${PASSWORD}"
open -a "Google Chrome" "http://localhost:8002/?user=$USERNAME&pass=$PASSWORD"
kubectl port-forward --namespace monitoring svc/prometheus-grafana 8002:80