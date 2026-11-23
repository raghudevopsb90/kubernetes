install:
	helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
	helm upgrade -i kps prometheus-community/kube-prometheus-stack -n monitoring --create-namespace -f values.yml
	kubectl apply -f servicemonitor.yml

uninstall:
	kubectl delete -f servicemonitor.yml
	helm uninstall kps -n monitoring
