#!/bin/bash

set -e

IMAGE_DIR=$1
FEDORA_IMAGE_URL=https://kojipkgs.fedoraproject.org/compose/cloud/latest-Fedora-Cloud-41/compose/Cloud/aarch64/images/Fedora-Cloud-Base-AmazonEC2-41-20250115.0.aarch64.raw.xz
FEDORA_VERSION=41

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

get_host_timezone(){
  if [[ "$OSTYPE" == "linux-gnu" ]]; then
    echo "$(cat /etc/timezone)"
  elif [[ "$OSTYPE" == "darwin"* ]]; then
    echo -e "from time import gmtime, strftime\nprint(strftime('%Z', gmtime()))" | python
  else # just return UTC since we don't know how to extract the host timezone
     echo "UTC"
  fi
}

gen_password() {
  podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt user1
}

create_user_data(){
    echo "#### 3. Create user-data file"
    YOUR_SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
    HOST_TIMEZONE=$(get_host_timezone)
    sed "s|SSH_PUBLIC_KEY|${YOUR_SSH_KEY}|g" ${CONFIG_DIR}/cloud-init/user-data.tpl > ${CONFIG_DIR}/cloud-init/user-data.tmp
    sed "s|TIMEZONE|${HOST_TIMEZONE}|g" ${CONFIG_DIR}/cloud-init/user-data.tmp > ${CONFIG_DIR}/cloud-init/user-data
    sed "s|GENPASSWORD|$(gen_password)|g" ${CONFIG_DIR}/cloud-init/user-data.tmp > ${CONFIG_DIR}/cloud-init/user-data
    rm ${CONFIG_DIR}/cloud-init/user-data.tmp
}

##
## Download Fedora iso file
##
wget_image() {
       echo "#### 1. Downloading $FEDORA_ISO_URL ..."
       wget --progress=bar -O Fedora-Cloud-$FEDORA_VERSION.raw.xz $FEDORA_IMAGE_URL
       cp Fedora-Cloud-$FEDORA_VERSION.raw.xz Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk
}


##
## Decompress the raw.tar.xz file
##
decompress() {
    echo "#### 2. Decompress the cloud raw.xz image file ..."
    gunzip -f -d Fedora-Cloud-$FEDORA_VERSION.raw.xz
}

##
## Generate the config-drive iso
##
gen_iso(){
    echo "#### 4. Generating ISO file containing user-data, meta-data files and used by cloud-init at bootstrap"
    mkisofs -output cloudinit.iso -volid cidata -joliet -r ${CONFIG_DIR}/cloud-init/meta-data ${CONFIG_DIR}/cloud-init/user-data
}

#wget_image
cp Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk Fedora-Cloud-$FEDORA_VERSION.raw.xz
decompress
create_user_data
gen_iso
ssh-keygen -R 192.168.64.4
echo "Done"