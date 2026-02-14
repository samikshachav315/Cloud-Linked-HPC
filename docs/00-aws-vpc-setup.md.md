# AWS VPC & Network Architecture

## 1. VPC Configuration
* **VPC Name:** `HPC-VPC`
* **IPv4 CIDR:** `10.0.0.0/16`

## 2. Overlay IP Setup (CRITICAL)
We use a **Overlay IP** (`192.168.2.50`) which is outside the VPC CIDR. This allows the IP to "float" between nodes by updating the VPC Route Table.

### A. Route Table Configuration
You must manually create the initial route entry in your **Private Route Table**:
* **Destination:** `192.168.2.50/32`
* **Target:** `i-xxxxxxxxx` (Instance ID of Controller-1)

*Note: The Pacemaker resource agent will automatically update this target to Controller-2 during a failover.*

### B. Security Groups
Add a rule to **SG-Cluster-Internal**:
* **Type:** All Traffic
* **Source:** `192.168.2.50/32`
* **Description:** Allow communication via Overlay IP