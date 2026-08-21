# Inception-of-Things — Beginner's Guide

This document explains the project **as if you've never touched Kubernetes,
Vagrant, or GitOps before**. Read it top to bottom before touching `p1`. Each
part builds on the previous one, so don't skip ahead.

If a term confuses you, check the [Glossary](#glossary) at the bottom first.

---

## 1. The big picture

The subject wants you to learn Kubernetes (K8s) gradually, using lighter-weight
tools than "real" production Kubernetes:

```
 Part 1              Part 2                Part 3               Bonus
┌─────────┐        ┌─────────┐        ┌───────────────┐   ┌───────────────┐
│ Vagrant │        │  1 VM   │        │  No Vagrant!  │   │  Add GitLab   │
│ 2 VMs   │  --->  │  K3s +  │  --->  │  K3d + ArgoCD │-->│  inside the   │
│ K3s     │        │ Ingress │        │   (GitOps)    │   │  Part 3 setup │
└─────────┘        └─────────┘        └───────────────┘   └───────────────┘
   "how do        "how do apps      "how do I deploy      "extra credit,
  clusters talk    get routed       automatically from    only if 1-3 are
   to each other?"  to the right    my Git repo, with      perfect"
                    container?"      zero manual steps?"
```

Each part is a **separate folder** at the repo root (`p1/`, `p2/`, `p3/`,
`bonus/`), each with its own `Vagrantfile` (if needed), a `scripts/` folder
(setup scripts) and a `confs/` folder (Kubernetes YAML manifests).

---

## 2. Concepts you need before starting

### Virtual Machines & Vagrant
A **VM** is a fake computer running inside your real computer. **Vagrant** is
a tool that reads one config file (`Vagrantfile`) and automatically creates,
configures, and boots VMs for you — so anyone on the team can run
`vagrant up` and get an identical machine. Under the hood it usually drives
VirtualBox (or another "provider").

```
Your laptop
┌──────────────────────────────────────────────┐
│  VirtualBox (the "provider")                   │
│  ┌───────────────┐      ┌───────────────┐      │
│  │   VM: loginS   │      │  VM: loginSW  │      │
│  │ 192.168.56.110 │      │192.168.56.111 │      │
│  └───────────────┘      └───────────────┘      │
└──────────────────────────────────────────────┘
```

### Kubernetes (K8s), in one paragraph
Kubernetes runs your applications inside **containers** (lightweight,
isolated processes — think "a tiny VM but way faster and cheaper") and
manages them automatically: restarting crashed ones, load-balancing traffic,
scaling up/down, etc. A Kubernetes "cluster" is made of:
- **Control plane / server / master**: the brain — decides what runs where.
- **Worker / agent node**: the muscle — actually runs your containers.
- **Pod**: the smallest deployable unit — usually one container (or a small
  group that share resources).
- **Deployment**: a rule that says "keep N replicas of this Pod running".
- **Service**: a stable network name/IP in front of a set of Pods (Pods'
  own IPs change all the time, so you never talk to them directly).
- **Ingress**: a rule that routes *external* HTTP traffic to the right
  Service based on hostname/path (like a reverse proxy / nginx rule, but
  Kubernetes-native).
- **Namespace**: a folder-like separation inside one cluster, so you can run
  unrelated things (e.g. `argocd` and `dev`) without them colliding.

`kubectl` (say "kube-control" or "kube-cuttle") is the CLI you use to talk to
a cluster: `kubectl get pods`, `kubectl get ns`, etc. Aliased to `k` in the
subject's examples.

### K3s vs K3d — the actual point of confusion in this project
| | K3s | K3d |
|---|---|---|
| What it is | A **real**, lightweight Kubernetes distribution (a single binary) | A tool that runs **K3s inside Docker containers** |
| Runs on | A VM or bare metal directly | Just needs Docker — no VM required |
| Used in | Part 1 & 2 (with Vagrant VMs) | Part 3 & Bonus (no Vagrant) |
| Analogy | "Kubernetes, but the installer is 1 binary instead of 100" | "K3s, but packaged as Docker containers so you don't even need a VM" |

So Part 1/2 = real VMs running K3s directly. Part 3 = no VMs at all, K3d
spins up your whole cluster as Docker containers on your normal OS.

### GitOps & Argo CD (Part 3's core idea)
Normally you deploy by running `kubectl apply -f my-file.yaml` manually.
**GitOps** flips this: your Git repository is the "source of truth" for what
*should* be running. A tool (**Argo CD**) constantly watches your repo and
automatically applies any change to the cluster — no manual `kubectl apply`
needed. You change a YAML file, `git push`, and the cluster updates itself
within seconds.

```
 You                 GitHub repo              Argo CD (in cluster)         dev namespace
┌─────┐   git push   ┌───────────┐   polls    ┌───────────────┐   applies  ┌─────────────┐
│ edit│ ───────────► │deployment │◄────────── │  watches repo  │ ─────────►│ Pod v1 → v2 │
│ yaml│               │  .yaml    │             │  for changes   │           └─────────────┘
└─────┘               └───────────┘             └───────────────┘
```

You are NOT running `kubectl apply` yourself in Part 3 — that's the entire
point. Argo CD does it for you because it's watching your public GitHub repo.

### Docker image tags (v1 / v2)
A Docker image can have multiple **tags** — think of them as labeled
snapshots/versions of the same app, e.g. `wil42/playground:v1` and
`wil42/playground:v2`. Changing which tag your `deployment.yaml` references
(and letting Argo CD sync it) is literally "how you deploy a new version" in
this project.

---

## 3. Part 1 — K3s and Vagrant (2 VMs)

**Goal:** two VMs talking to each other as a minimal Kubernetes cluster.

```
        192.168.56.110                    192.168.56.111
      ┌──────────────────┐              ┌──────────────────┐
      │   VM: <login>S    │   cluster    │  VM: <login>SW    │
      │  K3s SERVER mode   │◄───────────►│  K3s AGENT mode    │
      │  (control plane)   │   network    │  (worker node)     │
      └──────────────────┘              └──────────────────┘
        passwordless SSH                   passwordless SSH
```

Requirements checklist:
- [ ] Vagrantfile defines 2 VMs, minimal resources (1 CPU / 512-1024MB RAM).
- [ ] Hostnames: `<login>S` (server) and `<login>SW` (agent).
- [ ] Static IPs: `.110` (server) and `.111` (agent) on the same private network.
- [ ] Passwordless SSH into both.
- [ ] K3s installed in **server** mode on `<login>S`.
- [ ] K3s installed in **agent** mode on `<login>SW`, joined to the server
  (agent needs the server's URL + a join token, found on the server at
  `/var/lib/rancher/k3s/server/node-token`).
- [ ] `kubectl` available and working — `kubectl get nodes` should show both
  machines.

---

## 4. Part 2 — K3s and 3 apps behind an Ingress

**Goal:** one VM, one K3s server, 3 tiny web apps routed by the `Host` header.

```
                 192.168.56.110  (<login>S)
                        │
                        ▼
                 ┌─────────────┐
   request       │   Ingress    │   Host: app1.com ──► app1 (1 replica)
  Host: app1.com │  (traefik,   │   Host: app2.com ──► app2 (3 replicas)
  ─────────────► │  bundled     │   anything else  ──► app3 (default)
                  │  with K3s)   │
                  └─────────────┘
```

- Test with `curl -H "Host: app1.com" http://192.168.56.110` (or edit
  `/etc/hosts` on your real machine to map `app1.com`/`app2.com` to that IP
  and just use a browser).
- `app2` needs **3 replicas** — that's just `replicas: 3` in its Deployment.
- Anything that isn't `app1.com`/`app2.com` should fall back to `app3` — this
  is the Ingress's "default backend".

---

## 5. Part 3 — K3d and Argo CD (GitOps)

**Goal:** no Vagrant. Docker + K3d cluster on your own machine, with Argo CD
auto-deploying an app from a **public** GitHub repo (this one!).

```
┌─────────────────────────── K3d cluster (Docker containers) ───────────────────────────┐
│                                                                                          │
│   namespace: argocd                          namespace: dev                            │
│   ┌───────────────────┐    watches repo      ┌────────────────────────┐                │
│   │      Argo CD        │ ───────────────────►│  wil42/playground Pod   │                │
│   │  (deploys/syncs)     │   auto-applies       │  image tag: v1 or v2    │                │
│   └───────────────────┘                       └────────────────────────┘                │
└──────────────────────────────────────────────────────────────────────────────────────────┘
                     ▲
                     │ polls for changes
              ┌──────┴───────┐
              │ this GitHub  │
              │  repository  │
              │ (public!)     │
              └──────────────┘
```

Steps, in order:
1. Install Docker + K3d (write a `scripts/` install script — you must be able
   to run it live during your defense).
2. Create the cluster with K3d.
3. Create two namespaces: `argocd` and `dev`.
4. Install Argo CD into the `argocd` namespace.
5. Point Argo CD at **this repo** (a path inside `p3/confs/`, typically) so it
   deploys a `deployment.yaml` into the `dev` namespace.
6. Use either `wil42/playground` (Docker Hub, port 8888, tags `v1`/`v2` —
   ready-made, easiest option) or your own app pushed to your own public
   Docker Hub repo with two tagged versions.
7. To "deploy a new version": edit `deployment.yaml` in this repo to change
   the image tag (`v1` → `v2`), `git push`, then watch Argo CD auto-sync and
   confirm with `curl http://localhost:8888/` that the response changed.

---

## 6. Bonus — GitLab inside the Part 3 cluster

Only evaluated if Parts 1-3 are **flawless**. Add a local GitLab instance
(latest version, likely via Helm) in a new `gitlab` namespace, integrated into
the same cluster from Part 3, without breaking anything from Part 3.

```
   Part 3 cluster (K3d)
   ┌───────────────────────────────────────────────┐
   │  argocd ns   dev ns   gitlab ns (NEW — bonus)   │
   │  ┌──────┐   ┌──────┐  ┌──────────────────────┐  │
   │  │ArgoCD│   │ app  │  │  GitLab instance      │  │
   │  └──────┘   └──────┘  └──────────────────────┘  │
   └───────────────────────────────────────────────┘
```

---

## 7. Repo layout you must respect

```
.
├── p1/
│   ├── Vagrantfile
│   ├── scripts/
│   └── confs/
├── p2/
│   ├── Vagrantfile
│   ├── scripts/
│   └── confs/
├── p3/
│   ├── scripts/
│   └── confs/
└── bonus/
    ├── scripts/
    └── confs/
```
Folder names are **mandatory** — evaluators will check them literally.

---

## 8. Glossary

| Term | Meaning |
|---|---|
| **VM** | Virtual Machine — a simulated computer running on your real one |
| **Vagrant** | Tool to script/automate creating & configuring VMs |
| **Provider** | The virtualization backend Vagrant drives (e.g. VirtualBox) |
| **K3s** | Lightweight, real Kubernetes distribution (single binary) |
| **K3d** | Runs K3s inside Docker containers — no VM needed |
| **Cluster** | A set of machines (nodes) working together as one Kubernetes system |
| **Node** | One machine (VM or container) that's part of the cluster |
| **Server / control plane** | The node that makes scheduling decisions |
| **Agent / worker node** | The node that actually runs your app containers |
| **kubectl** | CLI tool to interact with a Kubernetes cluster |
| **Pod** | Smallest deployable unit in K8s; usually 1 container |
| **Deployment** | Manages a set of identical Pod replicas |
| **Replica** | A duplicate running copy of the same Pod, for load/availability |
| **Service** | Stable internal network address in front of a set of Pods |
| **Ingress** | Routes external HTTP traffic to Services based on hostname/path |
| **Namespace** | Logical partition inside a cluster (e.g. `dev`, `argocd`, `gitlab`) |
| **Docker image** | Packaged app + its dependencies, ready to run as a container |
| **Tag** | A version label on a Docker image (e.g. `:v1`, `:v2`) |
| **Docker Hub** | Public registry to store/share Docker images |
| **GitOps** | Practice of using a Git repo as the source of truth for what should run |
| **Argo CD** | Tool that watches a Git repo and auto-syncs the cluster to match it |
| **Helm** | Package manager for Kubernetes (used for the GitLab bonus) |
