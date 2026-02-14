# Cloud-Linked HPC: High-Availability AWS Cluster

> **A cloud-native High Performance Computing (HPC) infrastructure bridging traditional parallel processing with modern cloud resiliency.**

---

## 📖 Executive Summary
This project implements a production-grade **High-Availability (HA) HPC Cluster** within an AWS Virtual Private Cloud (VPC). [cite_start]Unlike standard on-premise clusters, this architecture solves the unique challenge of "Floating IPs" in the cloud by utilizing a custom **IP Reassignment Strategy** managed by Pacemaker [cite: 27-30].

The system features a **Self-Healing Compute Layer** powered by a custom Python Boto3 AI agent, ensuring that job capacity is automatically restored during node failures without human intervention.

---

# Table of Contents

1. [Cloud-Linked HPC: High-Availability AWS Cluster](#cloud-linked-hpc-high-availability-aws-cluster)
2. [Executive Summary](#-executive-summary)
3. [Architectural Design](#-architectural-design)
   - [High-Level Topology](#high-level-topology)
   - [Key Innovations](#-key-innovations)
     - [1. The AWS IP Failover Mechanism](#1-the-aws-ip-failover-mechanism)
     - [2. "AI" Recovery Agent (Compute Self-Healing)](#2-ai-recovery-agent-compute-self-healing)
4. [Technical Specifications](#-technical-specifications)
   - [🤖 AI Recovery Agent (Self-Healing)](#-ai-recovery-agent-self-healing)
   - [📂 Parallel Storage (BeeGFS)](#-parallel-storage-beegfs)
   - [⚡ Workload Management (Slurm)](#-workload-management-slurm)
   - [📊 Observability (ELK & Zabbix)](#-observability-elk--zabbix)
5. [Deployment Guide](#-deployment-guide)
   - [Prerequisites](#prerequisites)
   - [Installation Phases](#installation-phases)
     - [Phase 1: Infrastructure & HA Setup](#phase-1-infrastructure--ha-setup)
     - [Phase 2: Storage Fabric](#phase-2-storage-fabric)
     - [Phase 3: Scheduler & Compute](#phase-3-scheduler--compute)
     - [Phase 4: Operational Intelligence](#phase-4-operational-intelligence)
6. [Operational Playbook](#-operational-playbook)
   - [Verifying Cluster Status](#verifying-cluster-status)
   - [Simulating Failover Scenarios](#simulating-failover-scenarios)
     - [Scenario A: Controller Failover (Overlay IP)](#scenario-a-controller-failover-overlay-ip)
     - [Scenario B: Compute Node Auto-Recovery (AI Agent)](#scenario-b-compute-node-auto-recovery-ai-agent)
7. [Author](#-author)


---


## 🏗️ Architectural Design

### High-Level Topology
The cluster is segmented into **Public** (Monitoring/Bastion) and **Private** (Computation/Storage) subnets to adhere to the Principle of Least Privilege.

| Plane | Node Role | Technology Stack | IP Segment |
| :--- | :--- | :--- | :--- |
| **Control** | Active/Passive Controllers | Pacemaker, Corosync, PCS, SlurmCTLD | `10.0.2.x` |
| **Storage** | Parallel File System | BeeGFS (Mgmtd, Meta, Storage) | `10.0.2.x` |
| **Compute** | Workload Execution | SlurmD, Munge | `10.0.2.x` |
| **Monitor** | Observability | ELK Stack (Elastic, Logstash, Kibana), Zabbix | `10.0.1.x` |

### 🧠 Key Innovations

#### 1. The AWS IP Failover Mechanism
Standard Layer 2 gratuitous ARP broadcasts do not work in AWS VPCs. To achieve High Availability for the Controller, we use the AWS API to move a secondary IP address between instances.
* [cite_start]**Strategy:** We utilize a **Secondary Private IP** (`192.168.2.50`) that floats between the active and passive controllers[cite: 28].
* [cite_start]**Mechanism:** The `ocf:heartbeat:aws-vpc-move-ip` resource agent interacts with the AWS EC2 API[cite: 27].
* **Failover Logic:** When the active controller fails, Pacemaker triggers an API call to unassign `192.168.2.50` from the failed node and reassign it to the standby node's ENI (Elastic Network Interface).

#### 2. "AI" Recovery Agent (Compute Self-Healing)
While Slurm manages jobs, it does not manage AWS infrastructure. We bridge this gap with a custom agent.
* **Detection:** Polls EC2 Instance Status Checks and Slurm Node State (`sinfo`).
* **Remediation:** Triggers `boto3.start_instances()` API calls upon detecting `DOWN` or `IMPAIRED` states.
* **Resiliency:** Decouples infrastructure recovery from the job scheduler, preventing "zombie" nodes.

---

## 🛠️ Technical Specifications

### 🤖 AI Recovery Agent (Self-Healing)
A custom Python/Boto3 daemon that bridges the gap between the Slurm scheduler and AWS infrastructure.
* **Logic:** Polls `ec2:DescribeInstanceStatus` and Slurm's `sinfo` state every 30 seconds.
* **Trigger:** Activates when a compute node reports `InstanceStatus: Impaired` or `SystemStatus: Impaired`.
* **Action:** Executes `ec2:StartInstances` on the pre-configured cold standby node to restore cluster capacity.
* **Script:** `configs/aws-recovery/recovery_agent.py`

### 📂 Parallel Storage (BeeGFS)
[cite_start]Configured for high-throughput I/O with separated Metadata and Storage services to prevent bottlenecks [cite: 34-40].
* **Management/Metadata:** `10.0.2.20`
* [cite_start]**Storage Target:** 10GB Block Device (`/dev/sdb`) formatted as `ext4` [cite: 41-42].
* **Mount Point:** `/mnt/beegfs` (Client-side).

### ⚡ Workload Management (Slurm)
* [cite_start]**Version:** 20.11.9 (Compiled from source)[cite: 69].
* [cite_start]**Accounting:** MariaDB backend via `slurmdbd` for job history and usage tracking[cite: 113].
* [cite_start]**Authentication:** Munge cryptographic keys shared across the fleet[cite: 71].

### 📊 Observability (ELK & Zabbix)
A "Push-based" logging architecture where nodes ship data to a centralized secure bastion.
* [cite_start]**Log Pipeline:** `Filebeat` (Nodes) → `Logstash` (Parser) → `Elasticsearch` (Indexer) → `Kibana` (Visualizer) [cite: 185-191].
* [cite_start]**Grok Filters:** Custom patterns configured to parse Linux system logs and Slurm event logs [cite: 158-163].

---

## 🚀 Deployment Guide

### Prerequisites
1.  **AWS IAM Role:** Controllers must have `ec2:AssignPrivateIpAddresses`, `ec2:UnassignPrivateIpAddresses`, `ec2:DescribeInstances`, and `ec2:StartInstances` permissions.
2.  **Network:** Source/Destination Checks **disabled** on Controller EC2 instances (Critical for IP failover).
3.  **OS:** Ubuntu 22.04 LTS.

### Installation Phases

#### Phase 1: Infrastructure & HA Setup
Initialize the control plane and configure the AWS IP resource.
```bash
# Deploys Corosync ring and Pacemaker resources
sudo ./scripts/01-pcs-corosync-setup.sh

#Phase 2: Storage Fabric
Deploy the BeeGFS repositories, format block devices, and initialize services.

# Sets up Mgmtd, Meta, and Storage services
sudo ./scripts/02-beegfs-install.sh

#Phase 3: Scheduler & Compute
# Installs SlurmCTLD SlurmDBD(Control) and SlurmD (Compute)
sudo ./scripts/03-slurm-install.sh

#Phase 4: Operational Intelligence
# Start the Boto3 Failover Sentinel
python3 configs/aws-recovery/recovery_agent.py

# Deploy ELK Stack (on Monitoring Node)
sudo ./scripts/04-elk-setup.sh

🕹️ Operational Playbook
#Verifying Cluster Status

# Check HA Status (Should show 2 nodes Online and resources Started)
sudo pcs status

# Check Slurm Grid
sinfo -N -l

# Check Storage Pools
beegfs-ctl --listnodes --nodetype=storage


##Simulating Failover Scenarios

Scenario A: Controller Failover (Overlay IP)
Goal: Verify that the Floating IP (Overlay IP) automatically moves from the active controller to the standby controller when a failure occurs.
Identify the Active Node:
Run the status command on Controller-1:
sudo pcs status
Crash Active Node: sudo halt -f (Force immediate halt).
Observe: pcs status on the survivor node will show the peer as OFFLINE.
Run ip route or check AWS Console: The route 192.168.2.50/32 will point to the survivor.
Verify Network Routing:
Check the route table to ensure traffic is redirected.
Via AWS Console: Go to VPC > Route Tables. Check that the route for 10.0.2.50/32 (or your VIP) now points to the Instance ID of the survivor node.

Scenario B: Compute Node Auto-Recovery (AI Agent)
Goal: Verify that the custom Python/Boto3 AI Agent detects a failed compute node and automatically spins up the standby node to replace it.

Start the Recovery Agent:
On your monitoring/controller node, ensure the agent script is running and watching the logs:
# Run in background or separate terminal
python3 configs/aws-recovery/recovery_agent.py
Expected Log: INFO: Monitoring Compute-1... Status: running | Health: ok

Crash the Compute Node:
Terminate the primary compute instance (Compute-1) to simulate a hardware failure.
Option 1 (From the node): sudo halt -f
Option 2 (From AWS Console): Select Compute-1 -> Instance State -> Stop Instance.

Observe the AI Agent Response:
Watch the terminal where recovery_agent.py is running. You should see:

WARNING: Compute-1 Status: stopped | Health: critical
ALERT: Primary Compute Node Failed. Initiating Recovery...
INFO: Starting Standby Node i-0abcd1234efgh...
INFO: RECOVERY COMPLETE: Standby Node is Active.

Verify in Slurm & AWS:
AWS Console: Refresh the EC2 dashboard. You will see Compute-1 is Stopped and Compute-2 is Initializing/Running.
Slurm Controller: Run sinfo.
sinfo

Result: The partition state might temporarily show DOWN or DRAIN until the new node connects, then return to IDLE (Ready).




👤 Author
Prashant Bhopale
Email: prashantbhopale67@gmail.com
https://github.com/Prash2355


