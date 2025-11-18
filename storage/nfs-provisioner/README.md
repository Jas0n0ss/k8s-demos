https://artifacthub.io/packages/helm/nfs-subdir-external-provisioner/nfs-subdir-external-provisioner
https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner


```bash
# Setup NFS
sudo yum install nfs-utils.x86_64 -y
sudo mkdir -p /nfs && sudo chown nobody:nobody /nfs
sudo echo "/nfs 192.168.2.0/24(rw,sync,no_subtree_check,no_root_squash)" > /etc/exports
sudo systemctl enable --now nfs-server
[root@master-01 ~]# exportfs
/nfs          	192.168.2.0/24
```

```bash
helm repo add nfs-subdir-external-provisioner https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
    --set nfs.server=192.168.2.101 \
    --set nfs.path=/nfs \
    --namespace kube-system
```


```bash
[root@master-01 ~]# kubectl apply -f test-nfs.yaml
persistentvolumeclaim/test-nfs-pvc created
pod/busybox-nfs-test configured
[root@master-01 ~]# kubectl get pv
NAME                                       CAPACITY   ACCESS MODES   RECLAIM POLICY   STATUS   CLAIM              STORAGECLASS   VOLUMEATTRIBUTESCLASS   REASON   AGE
pvc-6d4b21e4-39cc-48f6-a5d3-9cd7e8920609   1Gi        RWX            Delete           Bound    lab/test-nfs-pvc   nfs-client     <unset>                          70s
[root@master-01 ~]# kubectl get pvc -n lab
NAME           STATUS   VOLUME                                     CAPACITY   ACCESS MODES   STORAGECLASS   VOLUMEATTRIBUTESCLASS   AGE
test-nfs-pvc   Bound    pvc-6d4b21e4-39cc-48f6-a5d3-9cd7e8920609   1Gi        RWX            nfs-client     <unset>                 82s
[root@master-01 ~]# ll /nfs/
total 0
drwxrwxrwx 2 root root 22 Nov 18 22:37 lab-test-nfs-pvc-pvc-6d4b21e4-39cc-48f6-a5d3-9cd7e8920609
[root@master-01 ~]#
```

