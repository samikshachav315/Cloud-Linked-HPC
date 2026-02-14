# HA Cluster Setup Guide

## 1. PCS & Corosync (Controller HA)
We install Pacemaker and Corosync on both controllers. [cite_start]Authentication is handled via the `hacluster` user[cite: 16]. [cite_start]The cluster is set to ignore quorum policies since we are running a 2-node setup[cite: 20].

### Resource Configuration
[cite_start]We configure a Virtual IP (VIP) resource that floats between controllers using the AWS VPC Move IP agent[cite: 27].
* **Resource Agent:** `ocf:heartbeat:aws-vpc-move-ip`
* [cite_start]**VIP Address:** `192.168.2.50` (Overlay IP) [cite: 28]
* [cite_start]**Interface:** `enp39s0` [cite: 29]
* [cite_start]**Region:** `us-east-1` [cite: 30]

## 2. BeeGFS Storage
BeeGFS is installed with the following layout:
* [cite_start]**Management Service:** 10.0.2.20 [cite: 46]
* [cite_start]**Metadata Service:** 10.0.2.20 [cite: 57]
* [cite_start]**Client Service:** Installed on all nodes [cite: 59]
* [cite_start]**Authentication:** `conn.auth` shared secret generated and distributed to `/etc/beegfs/`[cite: 49].

## 3. Slurm Workload Manager
[cite_start]Slurm 20.11.9 is compiled from source[cite: 73].
* [cite_start]**Authentication:** Munge is used for authentication, with keys shared between Controller and Compute nodes via SCP[cite: 79].
* [cite_start]**Database:** Configured with MariaDB (`slurmdbd`) for job accounting[cite: 106].
* [cite_start]**Paths:** Binaries are exported to `PATH` from `/slurm-dir/slurm-20.11.9/bin/`[cite: 102].

## 4. AWS Boto3 Recovery Agent (Compute HA)
We implement a custom "AI" recovery agent to handle **Compute Node** resiliency, separate from the controller HA.
* **Logic:** The Python script uses `boto3` to monitor the health of Compute-1.
* **Failover:** If Compute-1 fails status checks, the script automatically triggers the AWS API to start the standby node (Compute-2).
* **Source:** The script is located at `configs/aws-recovery/recovery_agent.py`.