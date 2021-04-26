kubectl apply -f cluster-autoscaler-autodiscover.yaml
kubectl -n kube-system logs -f deployment.apps/cluster-autoscaler