#!/bin/bash
# Run as root on the RHEL EC2 instance (t3.large or bigger)

dnf install -y dnf-plugins-core
dnf config-manager --add-repo https://download.docker.com/linux/rhel/docker-ce.repo
dnf install -y docker-ce docker-ce-cli containerd.io
systemctl enable --now docker
usermod -aG docker ec2-user

# kind runs every node as a container, multi-node clusters need more inotify watches
echo "fs.inotify.max_user_watches = 524288" >/etc/sysctl.d/99-kind.conf
echo "fs.inotify.max_user_instances = 512" >>/etc/sysctl.d/99-kind.conf
sysctl --system

curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/v0.33.0/kind-linux-amd64
curl -Lo /usr/local/bin/kubectl https://dl.k8s.io/release/v1.36.1/bin/linux/amd64/kubectl
chmod +x /usr/local/bin/kind /usr/local/bin/kubectl
curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
