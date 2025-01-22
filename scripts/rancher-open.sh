#!/bin/bash
open -a "Google Chrome" "https://localhost:8443/"
kubectl port-forward --namespace cattle-system svc/rancher 8443:443
