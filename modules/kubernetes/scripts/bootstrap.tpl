#!/bin/bash

### Dynamic vars (from terraform)

DATA_DIR_NAME=data
# shellcheck disable=SC2154
CONTROLLER_JOIN_TOKEN=${controller_join_token}
# shellcheck disable=SC2154
IS_WORKER=${is_worker}
# shellcheck disable=SC2154
CLUSTER_ID=${cluster_id}
# shellcheck disable=SC2154
AWS_REGION=${region}

### Statics

echo "START: $(date)" >> /opt/bootstrap_times

AWS_HOSTNAME=$(curl http://169.254.169.254/latest/meta-data/local-hostname)
hostname "$AWS_HOSTNAME"
echo "$AWS_HOSTNAME" > /etc/hostname
echo "127.0.0.1 $AWS_HOSTNAME" >> /etc/hosts

export DEBIAN_FRONTEND="noninteractive"

apt-get update
apt-get upgrade --assume-yes
apt-get autoremove --assume-yes
apt-get clean
locale-gen en_GB.UTF-8 # Will fix the warning when logging to the box

################################################# If it has drives

# Format drive if present
ISFORMATTED=$(file -s /dev/xvdi | grep -c '/dev/xvdi: data')
if [[ "$ISFORMATTED" == '1'  ]]
then
  mkfs -t ext4 /dev/xvdi
fi

# Mount drive if present
ISFORMATTED=$(file -s /dev/xvdi | grep -c 'ext4 filesystem data')
if [[ $ISFORMATTED == '1'  ]]
then
  mkdir /opt/$DATA_DIR_NAME
  cp /etc/fstab /etc/fstab.orig
  # As you are running Ubuntu 14.04 LTS it is important to be aware of some
  # performance bugs in the older kernel versions which can cause fsync to crash
  # the box, with the work-around being to mount the filesystem with the
  # data=writeback,relatime,nobarrier parameters. Further discussion around this
  # can be read
  # https://support.elastic.co/hc/en-us/requests/16385
  echo "/dev/xvdi       /opt/$DATA_DIR_NAME      ext4     data=writeback,relatime,nobarrier        0 0" >> /etc/fstab
  mount -a
fi

################

touch /opt/bootstrap_completed
echo "END: $(date)" >> /opt/bootstrap_times
