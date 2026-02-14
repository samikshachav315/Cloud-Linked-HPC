# ---------------------------------------------------------
# 1. Install Prerequisites & Add BeeGFS Repositories
# ---------------------------------------------------------
sudo apt update
sudo apt install curl -y
sudo apt install apt-transport-https -y

# [cite_start]Add BeeGFS GPG Key [cite: 36]
wget https://www.beegfs.io/release/beegfs_8.2/gpg/GPG-KEY-beegfs -O /etc/apt/trusted.gpg.d/beegfs.asc

# [cite_start]Add BeeGFS Repository List [cite: 37]
wget https://www.beegfs.io/release/beegfs_8.2/dists/beegfs-jammy.list -O /etc/apt/sources.list.d/beegfs.list

sudo apt update 

# [cite_start]Install BeeGFS Services (Management, Metadata, Storage, Client, Utils) [cite: 40]
sudo apt install -y beegfs-mgmtd beegfs-meta beegfs-tools beegfs-client beegfs-utils

# ---------------------------------------------------------
# 2. Configure Authentication (Shared Secret)
# MOVED UP: Must be done before starting ANY BeeGFS service
# ---------------------------------------------------------
# [cite_start]Generate connection authentication file [cite: 49]
sudo dd if=/dev/random of=/etc/beegfs/conn.auth bs=128 count=1
sudo chown root:root /etc/beegfs/conn.auth
sudo chmod 400 /etc/beegfs/conn.auth

# ---------------------------------------------------------
# 3. Prepare Storage (Disk Setup)
# ---------------------------------------------------------
# (10GB storage added) [cite_start][cite: 41]
sudo mkfs.ext4 /dev/sdb
sudo mkdir -p /data/beegfs
sudo mount /dev/sdb /data/beegfs

# [cite_start]Create directories for services [cite: 45]
sudo mkdir -p /data/beegfs/mgmtd /data/beegfs/meta /data/beegfs/storage

# ---------------------------------------------------------
# 4. Configure & Start Management Service (Mgmtd)
# ---------------------------------------------------------
# [cite_start]Initialize Management Database [cite: 52]
# Using the helper script is safer than manual edits
sudo /opt/beegfs/sbin/beegfs-setup-mgmtd -p /data/beegfs/mgmtd -m 10.0.2.20

# [cite_start]Start Management Service [cite: 53]
sudo systemctl start beegfs-mgmtd

# ---------------------------------------------------------
# 5. Configure & Start Storage Service
# ---------------------------------------------------------
# [cite_start]Setup storage directory and point to management node IP (10.0.2.20) [cite: 46]
sudo /opt/beegfs/sbin/beegfs-setup-storage -p /data/beegfs/storage -m 10.0.2.20

# [cite_start]Start Storage Service [cite: 47]
sudo systemctl start beegfs-storage

# ---------------------------------------------------------
# 6. Configure & Start Metadata Service
# ---------------------------------------------------------
# CORRECTION: Pointing to /data/beegfs/meta (your mounted disk), not /var/beegfs/meta
sudo /opt/beegfs/sbin/beegfs-setup-meta -p /data/beegfs/meta -m 10.0.2.20

# [cite_start]Start Metadata Service [cite: 58]
sudo systemctl start beegfs-meta

# ---------------------------------------------------------
# 7. Configure Client
# ---------------------------------------------------------
# [cite_start]Setup client to talk to management node [cite: 59]
sudo /opt/beegfs/sbin/beegfs-setup-client -m 10.0.2.20

# Configure mounts
# [cite_start]CORRECTION: Added missing '/' at the start of the path [cite: 60]
sudo vim /etc/beegfs/beegfs-mounts.conf

# [cite_start]Start Client Service [cite: 61]
sudo systemctl start beegfs-client