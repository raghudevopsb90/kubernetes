# kubernetes

Kubernetes topics in teaching order. Part 1 runs on a kind cluster on one EC2 instance. Part 2 moves to EKS for the things only a cloud cluster can do.

## Part 1: kind on EC2

Instance: RHEL, t3.large or bigger, security group open for 80 and 30080.

```bash
sudo bash 01-kind-cluster/install.sh
# log out and back in, so ec2-user picks up the docker group
cd 01-kind-cluster && make create
```

The cluster has one control-plane node and two workers (`learn-worker`, `learn-worker2`).

| # | Topic | Needs first |
|---|---|---|
| 01 | kind cluster | |
| 02 | Pod | |
| 03 | Multi-container pod, shared emptyDir | |
| 04 | Init container | |
| 05 | Sidecar container | |
| 06 | Ephemeral container (`kubectl debug`) | |
| 07 | Labels and annotations | |
| 08 | Namespace | |
| 09 | Environment variables | |
| 10 | ConfigMap | |
| 11 | Secret | |
| 12 | ReplicaSet | |
| 13 | Deployment, rolling update, rollback | |
| 14 | hostPort | |
| 15 | Service: ClusterIP | |
| 16 | Service: NodePort | |
| 17 | Probes: startup, readiness, liveness | |
| 18 | Requests and limits, OOMKilled | |
| 19 | ResourceQuota and LimitRange | |
| 20 | Job | |
| 21 | CronJob | |
| 22 | DaemonSet | |
| 23 | PersistentVolumeClaim | |
| 24 | StatefulSet with headless Service | |
| 25 | nodeSelector | node label |
| 26 | Taints and tolerations | node taint |
| 27 | Node affinity | node labels |
| 28 | Pod affinity and anti-affinity | |
| 29 | Topology spread constraints | |
| 30 | PriorityClass and preemption | |
| 31 | PodDisruptionBudget | |
| 32 | ServiceAccount and RBAC | |
| 33 | Security context | |
| 34 | Pod Security Standards | |
| 35 | NetworkPolicy | |
| 36 | HPA | metrics-server |
| 37 | VPA | metrics-server, VPA chart |
| 38 | Ingress | ingress-nginx |
| 39 | Gateway API, canary split | Envoy Gateway |
| 40 | Helm chart | |
| 41 | Kustomize | |
| 42 | Istio: sidecar, traffic split, mTLS | Istio charts |
| 43 | Prometheus and Grafana | kube-prometheus-stack |

The install commands for anything in "Needs first" are at the top of that topic's file.

## Part 2: EKS

```bash
cd 44-eks-cluster
make apply       # cluster, spot node group, add-ons, IAM roles for pods
make addons      # AWS Load Balancer Controller, External Secrets, Karpenter
make destroy     # when done, it costs money every hour
```

| # | Topic |
|---|---|
| 44 | EKS cluster with Terraform, Pod Identity roles |
| 45 | EBS StorageClass (gp3) and PVC |
| 46 | Pod Identity: a pod reads Parameter Store |
| 47 | External Secrets from Parameter Store |
| 48 | Service type LoadBalancer (NLB) |
| 49 | Ingress with ALB |
| 50 | Karpenter NodePool and consolidation |

Terraform state is local. Move it to an S3 backend before more than one person uses it.
