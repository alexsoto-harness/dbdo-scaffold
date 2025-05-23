# dbd-workshop-setup


## Kubernetes Configuration

```
kubectl create namespace db-lab
kubectl apply -n db-lab -f seed-data.yaml
kubectl apply -n db-lab -f dbs.yaml
```

## Harness Configuration

_this assumes you have a delegate and the Kubernetes cluster with the name DBDevOps already configured_

```
export HARNESS_ACCOUNT=""
export HARNESS_KEY=""

terraform init
terraform apply -auto-approve -var="key=$HARNESS_KEY" -var="account=$HARNESS_ACCOUNT" -var="project_name=username" -var="namespace=userspace"
```
