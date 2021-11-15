Curve-Helm
===

Curve-Helm helps deploy Curve cluster orchestrated by Kubernetes

> NOTE: This library is **not** yet production ready.

Requirement
---

| item                                                                         | version |
| :---                                                                         | :---    |
| [kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/) | v1.22.* |
| [helm](https://helm.sh/docs/intro/install/)                                  | v3.*    | 

 
Quick Start
---

#### Step1: Prepare toplogy configure

```shell
$ vi topology.yaml
```

```shell
global:
  image: opencurvedocker/curvefs:beta

etcd:
  enabled: true
  replicas: 3

mds:
  enabled: true
  replicas: 3

metaserver:
  enabled: true
  replicas: 3
  logDir: /mnt/logs
  dataDir: /mnt/data
  config:
    metaserver.loglevel: 0
```

#### Step2: Add labels to Kubernetes node

```shell
$ kubectl label node <NODENAME> curvefs-etcd=true 
$ kubectl label node <NODENAME> curvefs-mds=true 
$ kubectl label node <NODENAME> curvefs-metaserver=true 
```

#### Step3: Deploy cluster

```shell
$ helm upgrade --install curvefs-release ./curvefs -f topology.yaml -n curvefs --create-namespace
```
