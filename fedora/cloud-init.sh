#!/bin/bash

set -e

FEDORA_IMAGE_URL=https://kojipkgs.fedoraproject.org/compose/cloud/latest-Fedora-Cloud-41/compose/Cloud/aarch64/images/Fedora-Cloud-Base-AmazonEC2-41-20250115.0.aarch64.raw.xz
FEDORA_VERSION=41

CONFIG_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PWD_DIR=$(pwd)
IMG_DIR=$(pwd)/fedora

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
    echo "#### 2. Decompress the Fedora-Cloud-$FEDORA_VERSION.raw.xz file ..."
    gunzip -f -d $PWD_DIR/fedora/Fedora-Cloud-$FEDORA_VERSION.raw.xz
}

create_user_data(){
    echo "#### 3. Create user-data & meta-data files"
    YOUR_SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
    HOST_TIMEZONE=$(get_host_timezone)
    sed "s|SSH_PUBLIC_KEY|${YOUR_SSH_KEY}|g" ${CONFIG_DIR}/cloud-init/user-data.tpl > ${CONFIG_DIR}/cloud-init/user-data.tmp
    sed "s|TIMEZONE|${HOST_TIMEZONE}|g" ${CONFIG_DIR}/cloud-init/user-data.tmp > ${CONFIG_DIR}/cloud-init/user-data
    sed "s|GENPASSWORD|$(gen_password)|g" ${CONFIG_DIR}/cloud-init/user-data.tmp > ${CONFIG_DIR}/cloud-init/user-data
    rm ${CONFIG_DIR}/cloud-init/user-data.tmp
}

##
## Generate the config-drive iso
##
gen_iso(){
    echo "#### 4. Generate ISO file containing user-data, meta-data files and used by cloud-init at bootstrap"
    mkisofs -output $IMG_DIR/cloudinit.iso -volid cidata -joliet -r ${CONFIG_DIR}/cloud-init/meta-data ${CONFIG_DIR}/cloud-init/user-data
}

##
## Restore image already downloaded
##
restore_image() {
  echo "#### 1. Restore image from: Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk file"
  cp $PWD_DIR/fedora/Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk $PWD_DIR/fedora/Fedora-Cloud-$FEDORA_VERSION.raw.xz
}

if [[ "$1" == "fetch" ]]; then
  wget_image
else
  restore_image
fi

decompress
create_user_data
gen_iso
echo "Done"