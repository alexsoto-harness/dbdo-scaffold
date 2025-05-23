# DBDevOps Workshop Setup


## Kubernetes Configuration

_Pick a unique namespace per user_

```
kubectl create namespace userspace
kubectl apply -n userspace -f seed-data.yaml
kubectl apply -n userspace -f dbs.yaml
```

## Harness Configuration

_this assumes you have a delegate and the Kubernetes cluster with the name DBDevOps already configured_

```
export HARNESS_ACCOUNT=""
export HARNESS_KEY=""

terraform init
terraform apply -auto-approve -var="key=$HARNESS_KEY" -var="account=$HARNESS_ACCOUNT" -var="project_name=username" -var="namespace=userspace"
```
