#!/bin/bash

set -e

FEDORA_IMAGE_URL=https://download.fedoraproject.org/pub/fedora/linux/releases/42/Cloud/aarch64/images/Fedora-Cloud-Base-AmazonEC2-42-1.1.aarch64.raw.xz
FEDORA_FILE_NAME=Fedora-Cloud-Base-AmazonEC2-42-1.1.aarch64.raw.xz
FEDORA_VERSION=42

EXEC_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
FEDORA_DIR=$EXEC_DIR/../fedora

OSTYPE=$(uname)

get_host_timezone(){
  if [[ "$OSTYPE" == "linux" ]]; then
    echo "$(cat /etc/timezone)"
  elif [[ "$OSTYPE" == "Darwin" ]]; then
    #echo -e "from time import gmtime, strftime\nprint(strftime('%Z', gmtime()))" | python
    echo $(readlink /etc/localtime | awk -F/ '{print $(NF-1) "/" $NF}')
  else # just return UTC since we don't know how to extract the host timezone
    echo "UTC"
  fi
}

gen_password() {
  podman run -ti --rm quay.io/coreos/mkpasswd --method=yescrypt dev
}

##
## Download Fedora iso file (optional)
##
wget_image() {
       echo "#### 1. Downloading $FEDORA_IMAGE_URL ..."
       wget --progress=bar -O $FEDORA_DIR/Fedora-Cloud-$FEDORA_VERSION.raw.xz $FEDORA_IMAGE_URL
       cp $FEDORA_DIR/Fedora-Cloud-$FEDORA_VERSION.raw.xz $FEDORA_DIR/Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk
}

##
## Restore image already downloaded
##
restore_image() {
  echo "#### 1. Restore image from: Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk file"
  cp $FEDORA_DIR/Fedora-Cloud-$FEDORA_VERSION.raw.xz.bk $FEDORA_DIR/Fedora-Cloud-$FEDORA_VERSION.raw.xz
}

##
## Decompress the raw.tar.xz file
##
decompress() {
    echo "#### 2. Decompress the Fedora-Cloud-$FEDORA_VERSION.raw.xz file ..."
    gunzip -f -d $FEDORA_DIR/Fedora-Cloud-$FEDORA_VERSION.raw.xz
}

create_user_data(){
    echo "#### 3. Create the user-data file"
    YOUR_SSH_KEY=$(cat ~/.ssh/id_rsa.pub)
    sed "s|SSH_PUBLIC_KEY|${YOUR_SSH_KEY}|g" ${FEDORA_DIR}/cloud-init/user-data.tpl > ${FEDORA_DIR}/cloud-init/user-data.tmp
    sed -e "s|TIME_ZONE|$(get_host_timezone)|g" -e "s|GENPASSWORD|$(gen_password)|g" ${FEDORA_DIR}/cloud-init/user-data.tmp > ${FEDORA_DIR}/cloud-init/user-data
    rm ${FEDORA_DIR}/cloud-init/user-data.tmp
}

if [[ "$1" == "fetch" ]]; then
  wget_image
else
  restore_image
fi

decompress
create_user_data
echo "Done"