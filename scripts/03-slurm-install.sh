
#Installation & Build (Run on Both Controller & Compute)
# 1. Prepare Environment & Disable Firewall (For internal testing)
sudo apt-get install openssh-server -y
sudo iptables -F
sudo systemctl stop ufw

# 2. Create Installation Directory
sudo mkdir /slurm-dir
cd /slurm-dir/

# 3. Download Slurm 20.11.9
sudo wget https://download.schedmd.com/slurm/slurm-20.11.9.tar.bz2
sudo tar -xvjf slurm-20.11.9.tar.bz2 

# 4. Install Build Dependencies
sudo apt install -y build-essential munge libmunge-dev libmunge2 libmysqlclient-dev libssl-dev libpam0g-dev libnuma-dev perl

# 5. Compile and Install Slurm
cd slurm-20.11.9/
sudo ./configure --prefix=/slurm-dir/slurm-20.11.9/
sudo make
sudo make install

#On Controller Node

# 1. Generate/Secure the Munge Key
sudo chown munge: /etc/munge/munge.key
sudo chmod 400 /etc/munge/munge.key

# 2. Send Key to Compute Node (Replace 'compute_ip' with actual IP)
sudo scp -r /etc/munge/munge.key compute@compute_ip:/tmp 

# 3. Set Permissions & Start Munge Service
sudo chown -R munge: /etc/munge/ /var/log/munge/
sudo chmod 0700 /etc/munge/ /var/log/munge/
sudo systemctl enable munge
sudo systemctl start munge
sudo systemctl status munge

#On Controller Node

# 1. Install the Key from Controller
sudo cp /tmp/munge.key /etc/munge

# 2. Start Munge Service
sudo systemctl enable munge
sudo systemctl start munge
sudo systemctl status munge

#Controller Configuration

# 1. Setup Configuration File
cd /slurm-dir/slurm-20.11.9/etc
cp slurm.conf.example slurm.conf
sudo vim slurm.conf  # Edit this file to define your nodes and partitions

# 2. Setup Systemd Services
sudo ln -s /slurm-dir/slurm-20.11.9/etc/slurmctld.service /usr/lib/systemd/system/slurmctld.service
sudo ln -s /slurm-dir/slurm-20.11.9/etc/slurmd.service /usr/lib/systemd/system/slurmd.service

# 3. Initialize Controller Storage & Start Service
sudo mkdir -p /var/spool/slurm/ctld
sudo sbin/slurmctld -D       # Test config (Ctrl+C to exit if it hangs)
sudo service slurmctld restart
sudo service slurmctld status

# 4. Setup Environment Variables (Add these to ~/.bashrc for persistence)
export PATH="/slurm-dir/slurm-20.11.9/bin/:$PATH"
export PATH="/slurm-dir/slurm-20.11.9/sbin/:$PATH"
export LD_LIBRARY_PATH="/slurm-dir/slurm-20.11.9/lib/:$LD_LIBRARY_PATH"

# 5. Check Cluster State
sinfo

# 6. Configure Slurm Database (Optional but recommended)
sudo cp slurmdbd.conf.example slurmdbd.conf
sudo nano slurmdbd.conf
sudo ln -s /slurm-dir/slurm-20.11.9/etc/slurmdbd.service /usr/lib/systemd/system/slurmdbd.service
sudo chmod 600 /slurm-dir/slurm-20.11.9/etc/slurmdbd.conf

# 7. Start Database Services
sudo apt-get install mariadb-server
sudo sbin/slurmdbd -D        # Test DB config
sudo service slurmdbd start
sudo service slurmdbd status

# 8. Send Configuration to Compute Node
scp slurm.conf controller@compute:/tmp

#Compute Node Configuration

# 1. Install Configuration from Controller
sudo cp /tmp/slurm.conf /slurm-dir/slurm-20.11.9/etc/slurm.conf

# 2. Setup Systemd Service
sudo ln -s /slurm-dir/slurm-20.11.9/etc/slurmd.service /usr/lib/systemd/system/slurmd.service

# 3. Create Spool Directory
sudo mkdir -p /var/spool/slurm/d
sudo chmod 0755 /var/spool/slurm/d

# 4. Start Slurm Daemon
sudo sbin/slurmd -D          # Test config (Ctrl+C to exit)
sudo systemctl start slurmd
sudo systemctl status slurmd
