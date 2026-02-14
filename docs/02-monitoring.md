# Monitoring & Logging Architecture

## Overview
The cluster utilizes a dedicated **Monitoring Node** located in the **Public Subnet** (`10.0.1.x`) to aggregate logs and metrics from the private cluster nodes.

## 1. ELK Stack (Logging)
We utilize the Elastic Stack (ELK) to centralize system logs from all nodes.

### Components
* **Elasticsearch:** Stores indexed log data. [cite_start]Listens on port `9200` on `0.0.0.0` [cite: 141-142].
* [cite_start]**Logstash:** Processing pipeline that receives logs on port `5044`[cite: 155]. [cite_start]It parses system syslog messages using Grok filters[cite: 160].
* [cite_start]**Kibana:** Visualization dashboard accessible via browser at `http://<Public-IP>:5601`[cite: 178, 184].
* [cite_start]**Filebeat:** Lightweight shipper installed on **ALL** cluster nodes (Controllers, Compute, Storage)[cite: 185]. [cite_start]It reads system logs and forwards them to Logstash on the monitor node [cite: 190-191].

### Configuration Highlights
* [cite_start]**Logstash Input:** configured to accept Beats protocol on port 5044 [cite: 154-155].
* [cite_start]**Logstash Output:** Sends processed data to Elasticsearch with daily indices (`%{+YYYY.MM.dd}`)[cite: 168].
* [cite_start]**Filebeat Output:** Hardcoded to point to the monitor node: `hosts: ["monitor-1:5044"]`[cite: 191].

## 2. Zabbix (Infrastructure Monitoring)
* **Role:** Zabbix Server runs on the Monitoring Node to track CPU, Memory, and Network health of the cluster.
* **Agents:** Zabbix Agents are deployed on all private nodes (Controllers, Compute 1/2, Storage) to report metrics back to the public server.
* **Alerting:** Configured to trigger alerts if nodes become unreachable (complementing the AI Recovery Agent).

## 3. Network Access
To access these dashboards, the **Security Group** (`SG-Monitoring-Public`) allows:
* **TCP 5601:** Kibana Dashboard
* **TCP 80/443:** Zabbix Web Interface
* **TCP 5044 & 10051:** Internal traffic from private nodes for log/metric shipping.