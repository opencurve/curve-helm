Name
===

curve-helm - Helps deploy Curve cluster orchestrated by Kubernetes.

Status
===

This library is **not** yet production ready.

Table of Contents
===

* [Name](#name)
* [Status](#status)
* [Requirement](#requirement)
* [Quick Start](#quick-start) 

Requirement
---

| item                                                                         | version |
| :---                                                                         | :---    |
| [kubernetes](https://kubernetes.io/docs/setup/production-environment/tools/) | v1.22.* |
| [helm](https://helm.sh/docs/intro/install/)                                  | v3.*    | 

[Back to TOC](#table-of-contents)
 
Quick Start
---

#### Step1: Prepare topology configure

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
$ kubectl label node <nodename> curvefs-etcd=true 
$ kubectl label node <nodename> curvefs-mds=true 
$ kubectl label node <nodename> curvefs-metaserver=true 
```

#### Step3: Deploy cluster by helm

```shell
$ helm upgrade --install curvefs-release ./curvefs -f topology.yaml -n curvefs --create-namespace
```

[Back to TOC](#table-of-contents)
