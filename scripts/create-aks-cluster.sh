RESOURCEGROUP=kubernetes-eu
CLUSTERNAME=kubernetes-eu
LOCATION=westeurope
VMSIZE=Standard_B2s # Cheapest option, you can increase this if you have more budget
VMDISKSIZE=30 # Keep this to the max size the VM allows
RANCHERDNS=rancher.bach.software
PLAUSIBLE_DNS=plausible.bach.software
LETSENCRYPTEMAIL=jeroen@bach.software

#az login
az group create --name $RESOURCEGROUP --location $LOCATION
az aks create --resource-group $RESOURCEGROUP --name $CLUSTERNAME --node-vm-size $VMSIZE --node-count 1 --generate-ssh-keys --location $LOCATION --load-balancer-sku standard --node-osdisk-type Ephemeral --node-osdisk-size $VMDISKSIZE
#--kubernetes-version 1.30.6
az aks get-credentials --resource-group $RESOURCEGROUP --name $CLUSTERNAME

# Create the letsencrypt cluster issuers
helm repo add jetstack https://charts.jetstack.io
helm repo update
helm install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set crds.enabled=true
kubectl create -f cluster-issuer.yml

# Install nginx ingress controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install \
  ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=LoadBalancer \
  --set controller.service.annotations."service\.beta\.kubernetes\.io/azure-load-balancer-health-probe-request-path"=/healthz \
  --set controller.service.externalTrafficPolicy=Local \
  --create-namespace
#  --version 4.12.0 \

echo "Waiting for the external ip to be assigned to the ingress controller, once it is available you can stop this script"
kubectl get service --namespace ingress-nginx ingress-nginx-controller --output wide --watch
read -p "Add the ip to your dns. Press enter to continue"

read -p "Do you want to install Rancher? Press enter to continue"

# Install Rancher
helm repo add rancher-stable https://releases.rancher.com/server-charts/stable
#kubectl create namespace cattle-system
helm upgrade --install rancher rancher-stable/rancher \
  --namespace cattle-system \
  --set hostname=$RANCHERDNS \
  --set ingress.tls.source=letsEncrypt \
  --set letsEncrypt.email=$LETSENCRYPTEMAIL \
  --set letsEncrypt.ingress.class=nginx \
  --set ingress.ingressClassName=nginx \
  --create-namespace

# --set bootstrapPassword=$ADMINPASSWORD \

kubectl -n cattle-system rollout status deploy/rancher

kubectl get secret --namespace cattle-system bootstrap-secret -o go-template='{{.data.bootstrapPassword|base64decode}}{{"\n"}}'

# Deploy Plausible Analytics using Helm
helm repo add imio https://imio.github.io/helm-charts
helm repo update
helm upgrade --install plausible-analytics imio/plausible-analytics \
  --namespace plausible-analytics \
  --create-namespace \
  --version 0.3.3 \
  --set baseURL="http://${PLAUSIBLE_DNS}" \
  --set postgresql.primary.persistence.enabled=true \
  --set postgresql.primary.persistence.existingClaim=pvc-disk-plausible-postgresql-0 \
  --set postgresql.primary.persistence.size=1Gi \
  --set clickhouse.persistence.enabled=true \
  --set clickhouse.persistence.existingClaim=pvc-disk-plausible-clickhouse-0 \
  --set clickhouse.persistence.size=8Gi \
  --set ingress.enabled=true \
  --set ingress.annotations."cert-manager\.io/cluster-issuer"="letsencrypt-production" \
  --set ingress.annotations."kubernetes\.io/ingress\.class"=nginx \
  --set ingress.annotations."kubernetes\.io/tls-acme"="true" \
  --set ingress.className=nginx \
  --set ingress.hosts[0].host=${PLAUSIBLE_DNS} \
  --set ingress.hosts[0].paths[0].path=/ \
  --set ingress.tls[0].secretName=letsencrypt-production \
  --set ingress.tls[0].hosts[0]=${PLAUSIBLE_DNS}
