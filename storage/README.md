# Kubernetes 存储指南

## 📌 内容目录

- [Kubernetes 存储类型概览](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#kubernetes-存储类型概览)
- [1. EmptyDir](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#1-emptydir)
- [2. HostPath](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#2-hostpath)
- [3. NFS](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#3-nfs)
- [4. Ceph RBD / CephFS](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#4-ceph-rbd--cephfs)
- [5. Local Persistent Volume](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#5-local-persistent-volume)
- [6. CSI 驱动（云厂商）](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#6-csi-驱动云厂商)
- [7. Longhorn](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#7-longhorn)
- [8. OpenEBS](https://github.com/Jas0n0ss/k8s-demos/tree/main/storage#8-openebs)

------

## Kubernetes 存储类型概览

| 类型               | 描述                          | 典型使用场景                     |
| ------------------ | ----------------------------- | -------------------------------- |
| EmptyDir           | 临时存储，与 Pod 生命周期绑定 | 缓存、临时文件、中间计算结果     |
| HostPath           | 节点本地目录                  | 本地开发、调试、快速实验         |
| NFS                | 网络共享文件系统              | 多 Pod 共享文件、轻量级生产环境  |
| Ceph RBD / CephFS  | 分布式块存储与文件存储        | 企业级数据库、高可用、可扩展     |
| Local PV           | 节点本地磁盘                  | 高性能数据库、低延迟应用         |
| CSI 驱动（云厂商） | 云原生存储接口                | 云上生产环境、动态创建磁盘/NAS   |
| Longhorn           | 轻量级分布式存储              | K3s、边缘集群、无专用存储设备    |
| OpenEBS            | 容器原生本地存储              | 数据库、边缘节点、高性能本地磁盘 |

------

# 1. EmptyDir

- 官方文档: https://kubernetes.io/docs/concepts/storage/volumes/#emptydir
- YAML 示例:

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

# 2. HostPath

- 官方文档: https://kubernetes.io/docs/concepts/storage/volumes/#hostpath
- YAML 示例:

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

# 3. NFS

- 官方文档: https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner
- 安装 StorageClass:

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/
helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
  --set nfs.server=192.168.1.10 --set nfs.path=/export/data
```

- PVC 和 Pod 示例:

```yaml
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

# 4. Ceph RBD / CephFS

- 官方文档: https://github.com/ceph/ceph-csi
- 安装 CSI 插件:

```bash
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/devel/deploy/rbd/kubernetes/csi-rbdplugin.yaml
kubectl apply -f https://raw.githubusercontent.com/ceph/ceph-csi/devel/deploy/cephfs/kubernetes/csi-cephfsplugin.yaml
```

- StorageClass 示例:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: rook-ceph-block
provisioner: rook-ceph.rbd.csi.ceph.com
parameters:
  pool: replicapool
  imageFeatures: layering
reclaimPolicy: Delete
allowVolumeExpansion: true
```

# 5. Local Persistent Volume

- StorageClass 示例:

```yaml
apiVersion: storage.k8s.io/v1
kind: StorageClass
metadata:
  name: local-storage
provisioner: kubernetes.io/no-provisioner
volumeBindingMode: WaitForFirstConsumer
```

# 6. CSI 驱动（云厂商）

- 官方文档:
  - AWS EBS: https://github.com/kubernetes-sigs/aws-ebs-csi-driver/tree/master/docs
  - GCP PD: https://github.com/kubernetes-sigs/gcp-compute-persistent-disk-csi-driver
  - Azure Disk: https://github.com/kubernetes-sigs/azuredisk-csi-driver
  - Alibaba Cloud: https://github.com/kubernetes-sigs/alibaba-cloud-csi-driver
- 安装示例（AWS）:

```bash
kubectl apply -k "github.com/kubernetes-sigs/aws-ebs-csi-driver/deploy/kubernetes/overlays/stable/ecr/?ref=release-1.36"
```

# 7. Longhorn

- 官方文档: https://longhorn.io/docs/
- 安装命令:

```bash
helm repo add longhorn https://charts.longhorn.io
helm install longhorn longhorn/longhorn --namespace longhorn-system --create-namespace
```

# 8. OpenEBS

- 官方文档: https://openebs.io/docs/
- 安装命令:

```bash
helm repo add openebs https://openebs.github.io/charts
helm install openebs openebs/openebs
```

