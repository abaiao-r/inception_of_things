# Inception-of-Things (IoT)

42 System Administration project: hands-on introduction to Kubernetes with
`Vagrant`, `K3s`, `K3d` and `Argo CD`.

> Check the [Wiki](https://github.com/abaiao-r/inception_of_things/wiki) if you want to know more.

## Team

| Login | Role |
|-------|------|
| abaiao-r | |
| pedgonca | |

## Project structure

Per subject requirements, each part lives in its own folder at the repo root.
The current implementation starts with the Part 1 Vagrant environment:

```
.
├── p1/           # Part 1: Vagrant baseline for 2 Debian VMs
│   ├── Vagrantfile
│   ├── scripts/
│   │   └── setup_server.sh
│   └── confs/
├── p2/           # Part 2: K3s and three simple applications (Ingress)
│   ├── Vagrantfile
│   ├── scripts/
│   └── confs/
├── p3/           # Part 3: K3d and Argo CD (GitOps)
│   ├── scripts/
│   └── confs/
└── bonus/        # Bonus: GitLab in the cluster (only if mandatory is flawless)
    ├── scripts/
    └── confs/
```

- `en.subject.pdf` — original subject document.

## Host setup

Install the tools on your host machine before running any part.

### Linux

Debian/Ubuntu base packages:

```bash
sudo apt update
sudo apt install -y git curl ca-certificates gnupg
```

Part 1 needs Vagrant and VirtualBox:

```bash
sudo apt install -y vagrant virtualbox
```

Later parts use Docker, `kubectl`, `k3d` and the Argo CD CLI. Prefer the
official repositories/installers for these tools:

- Docker Engine: <https://docs.docker.com/engine/install/>
- kubectl: <https://kubernetes.io/docs/tasks/tools/install-kubectl-linux/>
- k3d: <https://k3d.io/>
- Argo CD CLI: <https://argo-cd.readthedocs.io/en/stable/cli_installation/>

After installing Docker, allow your user to run it without `sudo`:

```bash
sudo usermod -aG docker "$USER"
newgrp docker
```

### macOS

Install Homebrew if it is missing:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Part 1 needs Vagrant and VirtualBox:

```bash
brew install --cask virtualbox vagrant
```

Later parts use Docker, `kubectl`, `k3d` and the Argo CD CLI:

```bash
brew install --cask docker
brew install kubectl k3d argocd
```

Open Docker Desktop once after installation so the Docker daemon starts.

Apple Silicon note: this Part 1 Vagrantfile uses VirtualBox with
`debian/bookworm64`, an amd64 box. Use a Linux host or Intel Mac for the most
reliable setup unless the Vagrant provider/box is updated for arm64.

### Quick check

```bash
git --version
vagrant --version
VBoxManage --version
docker --version
kubectl version --client
k3d version
argocd version --client
```

## Part 1: Vagrant + K3s Server

`p1/Vagrantfile` defines two Debian Bookworm VMs with VirtualBox:

| VM | Hostname | Private IP | CPU | Memory |
|----|----------|------------|-----|--------|
| Server | `pedgoncaS` | `192.168.56.110` | 1 | 512 MB |
| Worker | `pedgoncaSW` | `192.168.56.111` | 1 | 512 MB |

The server VM runs `p1/scripts/setup_server.sh` during provisioning. It:

- installs `curl`
- installs K3s as the server
- copies the K3s node token to `p1/k3s-node-token`

Start the environment:

```bash
cd p1
vagrant up
```

Useful commands:

```bash
vagrant status
vagrant provision pedgoncaS
vagrant ssh pedgoncaS
vagrant ssh pedgoncaSW
vagrant destroy -f
```

Check K3s on the server:

```bash
vagrant ssh pedgoncaS
sudo kubectl get nodes
```

`p1/k3s-node-token` is generated locally and ignored by Git. It is kept in the
shared Vagrant folder so the worker VM can join the cluster in the next setup
step.

## Subject targets

- **Part 1**: Two VMs via Vagrant (`<login>S` controller, `<login>SW` agent),
  static IPs `192.168.56.110` / `.111`, passwordless SSH, K3s server on the
  first VM and K3s agent on the second, `kubectl` available.
- **Part 2**: Single VM with K3s server, 3 web apps behind an Ingress routed by
  `Host` header (`app1.com`, `app2.com`, default → `app3`), app2 runs 3
  replicas.
- **Part 3**: K3d (no Vagrant), `argocd` and `dev` namespaces, Argo CD
  continuously deploying an app from this public GitHub repo, app image
  switchable between `v1`/`v2` tags.
- **Bonus**: Local GitLab integrated with the Part 3 cluster in a `gitlab`
  namespace (only evaluated if the mandatory part is fully working).

## Working agreement

See [CONTRIBUTING.md](CONTRIBUTING.md) for branch protection rules, PR
process and commit conventions used by this team.

## Status

Part 1 has a reproducible Vagrant baseline and automatic K3s server
provisioning. Worker node provisioning is the next step.
