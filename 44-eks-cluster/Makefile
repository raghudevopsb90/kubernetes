CLUSTER = learn-eks

apply:
	terraform init
	terraform apply -auto-approve
	aws eks update-kubeconfig --name $(CLUSTER) --region us-east-1

addons:
	helm repo add eks https://aws.github.io/eks-charts
	helm repo add external-secrets https://charts.external-secrets.io
	helm repo update
	helm upgrade -i aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --version 3.6.3 \
		--set clusterName=$(CLUSTER) --set vpcId=$$(terraform output -raw vpc_id) --set region=us-east-1
	helm upgrade -i external-secrets external-secrets/external-secrets -n external-secrets --create-namespace --version 2.15.0
	helm upgrade -i karpenter oci://public.ecr.aws/karpenter/karpenter -n kube-system --version 1.14.4 \
		--set settings.clusterName=$(CLUSTER) \
		--set controller.resources.requests.cpu=200m --set controller.resources.requests.memory=512Mi

# Load balancers and Karpenter nodes are created outside Terraform, remove them first
destroy:
	-kubectl delete -f ../48-eks-service-loadbalancer.yml -f ../49-eks-ingress-alb.yml -f ../50-eks-karpenter.yml --ignore-not-found
	-helm uninstall karpenter aws-load-balancer-controller -n kube-system
	terraform destroy -auto-approve
