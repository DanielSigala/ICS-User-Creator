#!/bin/bash

# Variables we will use including input from user
FIRST_NAME=$1
LAST_NAME=$2
PASSWORD=password
ROLE_NAME=ICSUser
HOST_NAME=9X-760-13
BRIDGE_IP=192.168.2.0/24

# Create username using first and last name
firstletter=${FIRST_NAME:0:1}
USER_NAME=$firstletter$LAST_NAME

# Create group name, pool name, and bridge name using username
GROUP_NAME="$USER_NAME"_GROUP
POOL_NAME="$USER_NAME"_POOL
BRIDGE_NAME="${USER_NAME}"br0

# Create pool
pveum pool add "$POOL_NAME" 
echo "Created pool: $POOL_NAME"

# Create group
pveum group add "$GROUP_NAME" 
echo "Created group: $GROUP_NAME"

# Create user and add to group
pveum user add "$USER_NAME"@pve --password "$PASSWORD" --group "$GROUP_NAME"
echo "Created user: $USER_NAME and added to group: $GROUP_NAME"

# Add group to pool and assign role
pveum acl modify /pool/"$POOL_NAME" --roles "$ROLE_NAME" --groups "$GROUP_NAME"
echo "Added group: $GROUP_NAME to pool: $POOL_NAME with role: $ROLE_NAME"

# Add storage as a member of resource pool
pvesh set /pools/"$POOL_NAME" --storage local
pvesh set /pools/"$POOL_NAME" --storage local-lvm
echo "Added storage: local to pool: $POOL_NAME"
echo "Added storage: local-lvm to pool: $POOL_NAME"

# Create linux network bridge
pvesh create /nodes/"$HOST_NAME"/network --iface "$BRIDGE_NAME" --type bridge --cidr "$BRIDGE_IP" --autostart 1
echo "Created network bridge: $BRIDGE_NAME"

# Add group to network bridge and assign role
pveum acl modify /sdn/zones/localnetwork/"$BRIDGE_NAME" --roles "$ROLE_NAME" --groups "$GROUP_NAME"
echo "Added group $GROUP_NAME to network bridge: $BRIDGE_NAME with role: $ROLE_NAME"

# Replace network file with temporary file and apply changes
cp /etc/network/interfaces.new /etc/network/interfaces
ifreload -a
echo "Applied network configuration"