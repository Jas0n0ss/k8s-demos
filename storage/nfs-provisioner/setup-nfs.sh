sudo yum install nfs-utils.x86_64 -y
sudo mkdir -p /mnt/nfs-share && sudo chown nobody:nobody /mnt/nfs-share
sudo cat > /etc/exports < EOF
/mnt/nfs-share 10.0.1.0/24(rw,sync,no_subtree_check,no_root_squash)
EOF
systemctl enable --now nfs-server
