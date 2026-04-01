# Installation Guide for K3s and JFrog Platform

This document is intended to guide the installation of K3s on a virtual machine in an online environment, and the deployment of the JFrog Platform on K3s using Helm. It is designed for scenarios where the user environment is constrained but allows controlled internet access via a whitelist.

## Chapter 1. System Requirements

| Item | Requirement |
|---|---:|
| CPU | 12 vCPU |
| Memory | 24 GB RAM |
| Storage | 500 GB |
| OS | 64-bit Linux |
| Network | HTTPS outbound access for online installation |
| Privileges | Root or sudo |

---

## Chapter 2. Install K3s and Helm

### 2.1 Official Installation URL

| Item | URL |
|---|---|
| K3s Quick Start | https://docs.k3s.io/quick-start |
| K3s Air-Gap Install | https://docs.k3s.io/installation/airgap |
| K3s Install Script | https://get.k3s.io |
| Helm Install Script | https://helm.sh/docs/intro/install |

### 2.2 K3s and Helm URL Whitelist 

| Domain | Purpose | Required |
|---|---|---|
| `get.k3s.io` | Download the K3s install script | Yes |
| `github.com` | Download K3s release binaries | Yes |
| `raw.githubusercontent.com` | Download K3s release binaries CDN | Yes |
| `auth.docker.io` | Pull Kubernetes base images | Yes |
| `docker.io` | Docker Hub registry endpoint | Yes |
| `registry-1.docker.io` | Docker Hub image pulls | Yes |
| `production.cloudflare.docker.com` | Docker Hub CDN | Yes |
| `get.helm.sh` | Helm install script | Yes |

### 2.3 Installation Steps

#### 2.3.1 Online Installation

| Step | Command |
|---|---|
| Install K3s server | `curl -sfL https://get.k3s.io \| sh -` |
| Check service | `systemctl status k3s` |
| Check node | `sudo k3s kubectl get nodes` |
| Check Pods | `sudo k3s kubectl get pods` |


#### 2.3.2 Air-Gap Installation

Document 
https://docs.k3s.io/installation/airgap?airgap-load-images=Manually+Deploy+Images




#### 2.3.3 Helm Installation

| Step | Command |
|---|---|
| Install Helm command line  | `curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-4 \| bash ` |
| Check install status | `helm --help` |
| Create env  | `mkdir -p ~/.kube` |
| Copy configuration  | `cp /etc/rancher/k3s/k3s.yaml ~/.kube/config` |
| chmod 600 to configuration| `chmod 600 ~/.kube/config` |
| Check service | `helm list` |


---


## Chapter 3. Install JFrog Platform

### 3.1 Official Installation URL

| Item | URL |
|---|---|
| JFrog Installation Docs | https://docs.jfrog.com/installation |
| Allowlisted URLs | https://docs.jfrog.com/installation/docs/allowlisted-urls-and-air-gapped-environment-considerations |
| Helm Install | https://docs.jfrog.com/installation/docs/install-the-jfrog-platform-using-helm-chart |

### 3.2 JFrog Domain Whitelist and Purpose

| Domain | Purpose | Required |
|---|---|---|
| `releases.jfrog.io` | Main source for JFrog installation binaries | Yes |
| `releases-docker.jfrog.io` | Main source for JFrog Docker images | Yes |
| `charts.jfrog.io` | JFrog Helm chart repository | Yes |
| `releases-cdn.jfrog.io` | CDN endpoint for JFrog downloads | Yes |
| `jes.jfrog.io` | JFrog Entitlements Server | License / Yes |
| `jcs.jfrog.io` | JFrog Consumption Server | Usage / Yes |
| `jxray.jfrog.io` | Xray database synchronization | Yes |
| `jfscatalogcentral.jfrog.io` | JFrog Security Catalog access | Security products only |
| `api.bintray.com` | Active JFrog Services | Yes |
| `jfrog-prod-use1-shared-virginia-main.s3.amazonaws.com` |  JFrog Charts CDN | Yes |

### 3.3 Installation Commands


#### 3.3.1 Helm install JFrog-Platform 

| Step | Command |
|---|---|
| Add repo | `helm repo add jfrog https://charts.jfrog.io` |
| Update repo | `helm repo update` |
| Install JFrog platform with artifactory xray catalog curation jas| `helm upgrade --install jfrog-platform jfrog/jfrog-platform  --namespace jfrog-platform --create-namespace --set artifactory.enabled=true --set xray.enabled=true --set catalog.enabled=true --set xray.serviceAccount.create=true --set  xray.rbac.create=true ` |
| Check pods | `kubectl  get po -n jfrog-platform` |

