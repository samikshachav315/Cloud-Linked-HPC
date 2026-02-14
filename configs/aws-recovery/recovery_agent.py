import boto3
import time
import logging

# Configuration
REGION = 'us-east-1'
PRIMARY_INSTANCE_ID = 'i'   # Replace with Compute 1 ID
STANDBY_INSTANCE_ID = 'i'   # Replace with Compute 2 ID

# Logging Setup
logging.basicConfig(level=logging.INFO, format='%(asctime)s - %(levelname)s - %(message)s')
logger = logging.getLogger()

ec2 = boto3.client('ec2', region_name=REGION)

def check_health(instanceid):
    try:
        response = ec2.describe_instance_status(InstanceIds=[instanceid])
        if not response['InstanceStatuses']:
            return "stopped", "unknown"
        state = response['InstanceStatuses'][0]['InstanceState']['Name']
        status = response['InstanceStatuses'][0]['InstanceStatus']['Status']
        return state, status
    except Exception as e:
        logger.error(f"Connection error: {e}")
        return "error", "error"

def trigger_failover():
    logger.warning("ALERT: Primary Compute Node Failed. Initiating Recovery...")
    
    # Start Standby
    ec2.start_instances(InstanceIds=[STANDBY_INSTANCE_ID])
    logger.info(f"Starting Standby Node {STANDBY_INSTANCE_ID}...")
    
    # Wait for ready state
    waiter = ec2.get_waiter('instance_running')
    waiter.wait(InstanceIds=[STANDBY_INSTANCE_ID])
    logger.info("RECOVERY COMPLETE: Standby Node is Active.")

def monitor():
    logger.info("AI Recovery Agent Started.")
    while True:
        state, health = check_health(PRIMARY_INSTANCE_ID)
        logger.info(f"Compute-1: {state} | Health: {health}")
        
        if state != 'running' or health != 'ok':
            trigger_failover()
            break 
        time.sleep(30)

if __name__ == "__main__":
    monitor()