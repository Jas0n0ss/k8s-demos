## 📌 内容目录

- ## 📌 内容目录

  - [Kubernetes 存储类型概览](#kubernetes-存储类型概览)
  - [1. EmptyDir](#1-emptydir)
  - [2. HostPath](#2-hostpath)
  - [3. NFS](#3-nfs)
  - [4. Ceph RBD / CephFS](#4-ceph-rbd--cephfs)
  - [5. Local Persistent Volume](#5-local-persistent-volume)
  - [6. CSI 驱动（云厂商）](#6-csi-驱动云厂商)
  - [7. Longhorn](#7-longhorn)
  - [8. OpenEBS](#8-openebs)

------

## Kubernetes 存储类型概览

| 类型                   | 描述                          | 典型使用场景                              |
| ---------------------- | ----------------------------- | ----------------------------------------- |
| **EmptyDir**           | 与 Pod 生命周期绑定的临时存储 | 缓存、临时文件、中间计算结果              |
| **HostPath**           | 直接读取节点本地文件系统      | 本地开发、单节点集群、调试测试            |
| **NFS**                | 网络共享文件系统              | 多 Pod 共享文件、共享配置、轻量级生产环境 |
| **Ceph RBD / CephFS**  | 分布式块存储与文件存储        | 企业级生产、数据库、海量数据、高可用      |
| **Local PV**           | 使用节点本地磁盘作为持久卷    | 高 IOPS/低延迟数据库任务、分析型工作负载  |
| **CSI 驱动（云厂商）** | 云原生标准化存储接口          | 云上生产环境、动态创建磁盘/NAS            |
| **Longhorn**           | 轻量级分布式存储（CNCF）      | K3s、边缘集群、无专用存储设备             |
| **OpenEBS**            | 容器原生本地存储              | 数据库、边缘节点、高性能本地磁盘          |

------

# 1. EmptyDir

### 📘 官方文档

https://kubernetes.io/docs/concepts/storage/volumes/#emptydir

### 📝 使用场景

- Web 应用缓存目录
- CI/CD 构建的临时文件
- 中间计算产物（如数据处理任务）
- 不适合用来存储需要持久化的数据

### 🚀 示例 YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: emptydir-demo
spec:
  containers:
    - name: app
      image: nginx
      volumeMounts:
        - mountPath: /cache
          name: cache-volume
  volumes:
    - name: cache-volume
      emptyDir: {}
```

------

# 2. HostPath

### 📘 官方文档

https://kubernetes.io/docs/concepts/storage/volumes/#hostpath

### 📝 使用场景

- 本地开发环境（minikube、kind）
- 直接读取节点上的日志或目录
- 调试、快速实验
- ⚠️ **生产环境不推荐使用**（不可移植、存在风险）

### 🚀 示例 YAML

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: hostpath-demo
spec:
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - mountPath: /data
          name: test-volume
  volumes:
    - name: test-volume
      hostPath:
        path: /tmp/data
        type: DirectoryOrCreate
```

------

# 3. NFS

### 📘 官方文档

https://kubernetes.io/docs/concepts/storage/volumes/#nfs

### 📝 使用场景

- 多 Pod 或多实例共享同一目录（RWX）
- 存储静态文件、共享配置、日志
- 适用于中小规模集群和轻量级生产系统
- 性能不及分布式存储（如 Ceph）

### 🚀 示例 YAML（已有 NFS 服务器）

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: nfs-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteMany
  nfs:
    server: 192.168.1.10
    path: "/export/data"
---
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: nfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  resources:
    requests:
      storage: 5Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: nfs-demo
spec:
  volumes:
    - name: nfs-storage
      persistentVolumeClaim:
        claimName: nfs-pvc
  containers:
    - name: app
      image: busybox
      command: ["sh", "-c", "sleep 3600"]
      volumeMounts:
        - name: nfs-storage
          mountPath: /mnt
```

------

# 4. Ceph RBD / CephFS

### 📘 官方文档

- CephFS: https://docs.ceph.com/en/latest/cephfs/
- RBD: https://docs.ceph.com/en/latest/rbd/
- Kubernetes: https://kubernetes.io/docs/concepts/storage/volumes/#cephfs

### 📝 使用场景

- 企业级生产环境（高可用、可扩展）
- 数据库（RBD 块存储）：MySQL / PostgreSQL / MongoDB
- 分布式文件共享（CephFS）
- 大规模集群、可靠性与扩容要求高的场景
- 与 Rook 配合形成原生 Kubernetes 存储系统

### 🚀 示例 YAML（Ceph CSI）

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: cephfs-pvc
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: cephfs-sc
  resources:
    requests:
      storage: 5Gi
```

------

# 5. Local Persistent Volume

### 📘 官方文档

https://kubernetes.io/docs/concepts/storage/volumes/#local

### 📝 使用场景

- 高性能存储（NVMe/SSD）
- 数据库（如 ClickHouse、Elasticsearch、Kafka）
- 延迟敏感型应用
- ⚠️ 不支持多节点容错（仅适用于单节点持久性需求）

### 🚀 示例 YAML

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: local-pv
spec:
  capacity:
    storage: 10Gi
  volumeMode: Filesystem
  accessModes:
    - ReadWriteOnce
  storageClassName: local-storage
  local:
    path: /mnt/disks/ssd1
  nodeAffinity:
    required:
      nodeSelectorTerms:
        - matchExpressions:
            - key: kubernetes.io/hostname
              operator: In
              values:
                - node1
```

------

# 6. CSI 驱动（云厂商）

Kubernetes 的主流存储方式，支持动态创建、快照、扩容等能力。

### 📝 使用场景

- 所有云平台上的生产环境
- 持久化磁盘（块存储）
- 文件存储（NAS）
- 动态扩容、备份、快照需求

### 👉 常见云厂商 CSI

| 云平台          | CSI 项目地址                                                 |
| --------------- | ------------------------------------------------------------ |
| AWS EBS         | https://github.com/kubernetes-sigs/aws-ebs-csi-driver        |
| Google Cloud PD | https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver |
| Azure Disk      | https://github.com/kubernetes-sigs/azuredisk-csi-driver      |
| Alibaba Cloud   | https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver  |

### 🚀 示例 YAML

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: csi-pvc
spec:
  accessModes: ["ReadWriteOnce"]
  storageClassName: csi-standard
  resources:
    requests:
      storage: 20Gi
```

------

# 7. Longhorn

### 📘 官方文档

https://longhorn.io/

### 📝 使用场景

- K3s / 边缘节点集群
- 无专用存储硬件的环境
- 简易部署的本地分布式存储
- Homelab / 小型生产环境

### 🚀 示例 YAML

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: longhorn-pvc
spec:
  storageClassName: longhorn
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

------

# 8. OpenEBS

### 📘 官方文档

https://openebs.io/

### 📝 使用场景

- 各类数据库（MySQL、PostgreSQL、MongoDB）本地持久化
- 边缘节点、混合环境
- 自由选择不同引擎（Jiva、cStor、Mayastor）
- 专注单节点或本地高性能存储

### 🚀 示例 YAML

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: openebs-pvc
spec:
  storageClassName: openebs-hostpath
  accessModes:
    - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
```

