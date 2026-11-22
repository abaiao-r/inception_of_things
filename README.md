# Inception-of-Things (IoT)

Build small Kubernetes labs with Vagrant, K3s, K3d, and Argo CD.

Read the [Wiki](https://github.com/abaiao-r/inception_of_things/wiki) for more
detail, or the [subject](en.subject.pdf) for the full requirements.

## At a glance

| Part | What is in this repo |
| --- | --- |
| [p1](p1/) | Two VMs: a K3s server and an agent. |
| [p2](p2/) | One K3s VM with app1 and three app2 replicas. App3 and Ingress are still needed. |
| [p3](p3/) | Placeholder folders for K3d and Argo CD. |
| [bonus](bonus/) | Placeholder folders for GitLab. |

Each part has its own folder at the repo root. Parts 1 and 2 both use a VM
named `pedgoncaS` at `192.168.56.110`. Stop one part before starting the other.

## Install host tools

Install tools on the host before starting a VM. Parts 1 and 2 use Vagrant and
VirtualBox. Later parts also need Docker, `kubectl`, `k3d`, and the Argo CD CLI.

### Linux

On Debian or Ubuntu, install the base packages:

```bash
sudo apt update
sudo apt install -y git curl ca-certificates gnupg
```

Install Vagrant and VirtualBox:

```bash
sudo apt install -y vagrant virtualbox
```

For later parts, use the official installers:

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

Install Homebrew if needed:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

Install Vagrant and VirtualBox:

```bash
brew install --cask virtualbox vagrant
```

For later parts, install Docker, `kubectl`, `k3d`, and the Argo CD CLI:

```bash
brew install --cask docker
brew install kubectl k3d argocd
```

Open Docker Desktop once after installation so the Docker daemon starts.

**Apple Silicon:** The Vagrantfiles use VirtualBox with the amd64
`debian/bookworm64` box. A Linux host or Intel Mac is the most reliable choice
unless the provider or box is updated for arm64.

### Check installed tools

```bash
git --version
vagrant --version
VBoxManage --version
docker --version
kubectl version --client
k3d version
argocd version --client
```

## Part 1: two-node K3s cluster

`p1/Vagrantfile` creates two Debian Bookworm VMs:

| VM | Role | IP | CPU | RAM |
| --- | --- | --- | --- | --- |
| `pedgoncaS` | Server | `192.168.56.110` | 1 | 1024 MB |
| `pedgoncaSW` | Agent | `192.168.56.111` | 1 | 512 MB |

**How it works:** Vagrant provisions K3s on both VMs. The server writes a join
token to the shared `/vagrant` folder. The agent reads it and joins the server
at `https://192.168.56.110:6443`. The local `p1/k3s-node-token` file is
ignored by Git.

**Start and check:**

```bash
cd p1
vagrant up
vagrant ssh pedgoncaS -c 'sudo kubectl get nodes'
```

The command should list `pedgoncaS` and `pedgoncaSW` as `Ready`.

**Other Vagrant commands** (run from `p1/`):

```bash
vagrant status
vagrant provision pedgoncaS
vagrant ssh pedgoncaS
vagrant ssh pedgoncaSW
vagrant destroy -f
```

## Part 2: K3s applications

`p2/Vagrantfile` creates one Debian VM: `pedgoncaS` at `192.168.56.110`,
with 1 CPU and 1500 MB RAM. Provisioning installs a K3s server, applies the
manifests in `p2/confs/`, and waits for the deployments.

| App | Image | Replicas | Service |
| --- | --- | --- | --- |
| app1 | `hashicorp/http-echo:0.2.3` | 1 | ClusterIP |
| app2 | `traefik/whoami` | 3 | ClusterIP |

App1 returns `app1`. The Services work inside the VM. There is no Ingress
yet, so the subject's host-based routing is not available.

**Start and check:**

```bash
cd p2
vagrant up
vagrant ssh pedgoncaS
sudo kubectl get deployments,pods,services
```

Run the `kubectl` command inside the VM. The two deployments should have
1 and 3 ready replicas, respectively.

**To finish Part 2:** Add app3 and an Ingress at `192.168.56.110`:

| Request host | Required app |
| --- | --- |
| `app1.com` | app1 |
| `app2.com` | app2 |
| Any other host | app3 |

## Later parts

**Part 3** calls for K3d, Argo CD, `argocd` and `dev` namespaces, and an app
deployed from this public GitHub repo. Changing its image tag from `v1` to
`v2` must update the app.

**Bonus** calls for local GitLab in a `gitlab` namespace, integrated with
Part 3. The subject assesses it only if all mandatory parts work.

## Team

`abaiao-r` and `pedgonca`. See [CONTRIBUTING.md](CONTRIBUTING.md) for the
team's PR and commit rules.
