#Install and Configure ELK on Monitoring Node
# 1. Update System & Configure Hosts
sudo apt update && sudo apt upgrade -y
sudo nano /etc/hosts  # Ensure 'monitor1' resolves to your IP

# 2. Install Java (OpenJDK 17)
sudo apt install openjdk-17-jdk -y
java -version

# 3. Add Elastic GPG Key
curl -fsSL https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo gpg --dearmor -o /usr/share/keyrings/elastic.gpg

# 4. Add Elastic Repository
echo "deb [signed-by=/usr/share/keyrings/elastic.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" | sudo tee /etc/apt/sources.list.d/elastic-8.x.list

# 5. Refresh Package List
sudo apt update

#Install & Configure Elasticsearch
# 1. Install Elasticsearch
sudo apt install elasticsearch -y

# 2. Configure Elasticsearch
sudo nano /etc/elasticsearch/elasticsearch.yml

# --- Add the following configuration inside the file ---
cluster.name: elk-cluster
node.name: monitor1
network.host: 0.0.0.0
http.port: 9200
discovery.type: single-node
# -----------------------------------------------------

# 3. Start Service
sudo systemctl daemon-reexec
sudo systemctl enable elasticsearch
sudo systemctl start elasticsearch

# 4. Verify Node is Running
curl http://localhost:9200

#Install & Configure Logstash
# 1. Install Logstash
sudo apt install logstash -y

# 2. Create Pipeline Configuration
sudo nano /etc/logstash/conf.d/elk.conf

# --- Add the following configuration inside the file ---
input {
  beats {
    port => 5044
  }
}

filter {
  if [fileset][module] == "system" {
    grok {
      match => { "message" => "%{SYSLOGBASE} %{GREEDYDATA:msg}" }
    }
  }
}

output {
  elasticsearch {
    hosts => ["http://localhost:9200"]
    index => "%{[@metadata][beat]}-%{+YYYY.MM.dd}"
  }
}
# -----------------------------------------------------

# 3. Start Logstash Service
sudo systemctl enable logstash
sudo systemctl start logstash
sudo systemctl status logstash

#Install & Configure Kibana

# 1. Install Kibana
sudo apt install kibana -y

# 2. Configure Kibana
sudo nano /etc/kibana/kibana.yml

# --- Add the following configuration inside the file ---
server.port: 5601
server.host: "0.0.0.0"
elasticsearch.hosts: ["http://localhost:9200"]
# -----------------------------------------------------

# 3. Start Kibana Service
sudo systemctl enable kibana
sudo systemctl start kibana

# 4. Access Dashboard
# Open in browser: http://13.218.96.109:5601


#Install & Configure Filebeat (Run on ALL Nodes)
# 1. Install Filebeat
sudo apt install filebeat -y

# 2. Configure Filebeat Output
sudo nano /etc/filebeat/filebeat.yml

# --- Modify the output.logstash section ---
output.logstash:
  hosts: ["monitor-1:5044"]
# ------------------------------------------

# 3. Enable System Module (Pre-built dashboard configs)
sudo filebeat modules enable system

# 4. Setup & Start Service
sudo systemctl enable filebeat
sudo systemctl start filebeat

# 5. Check Status
sudo systemctl status filebeat

