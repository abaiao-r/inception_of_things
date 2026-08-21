# Inception-of-Things (IoT)

42 System Administration project: hands-on introduction to Kubernetes using
`Vagrant`, `K3s`, `K3d` and `Argo CD`.

## Team

| Login | Role |
|-------|------|
| abaiao-r | |
| _colleague_ | |

## Project structure

Per subject requirements, each part lives in its own folder at the repo root:

```
.
├── p1/           # Part 1: K3s and Vagrant (2 VMs, server + agent)
│   ├── Vagrantfile
│   ├── scripts/
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

## Requirements summary

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

Setup in progress — implementation of p1/p2/p3/bonus to be discussed and
tracked via issues/PRs.
