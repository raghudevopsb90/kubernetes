variable "cluster_name" {
  default = "learn-eks"
}

variable "k8s_version" {
  default = "1.35"
}

variable "node_instance_types" {
  default = ["t3.large", "t3a.large"]
}
