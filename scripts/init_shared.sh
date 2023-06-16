#!/bin/bash


# public repo supporting jupyterhub-tf terraform scripts

PUB_REPO="jupyterhub-tf-pub"
SHARED_DIR="/mnt/pvc"
NB_DIR="${SHARED_DIR}/datalab/shared"
NBDATA_DIR="${SHARED_DIR}/data"

# create shared dir if not present
if [ ! -d "$NB_DIR" ]
then
 mkdir -p "$NB_DIR"
fi


# if notebooks-latest is present get a new one
if [ -d "${NB_DIR}/notebooks-latest" ]
then
  rm -rf "${NB_DIR}/notebooks-latest"
fi

git clone https://github.com/astro-datalab/notebooks-latest.git "${NB_DIR}/notebooks-latest" || exit 1

if [ ! -d "${NBDATA_DIR}" ] && [ 1 -eq 2 ]
then
  mkdir "${NBDATA_DIR}"

  python3.9 << EOF || exit 1
from dl import storeClient
ANON_TOKEN = "anonymous.0.0.anon_access"
storeClient.get(token=ANON_TOKEN, fr="robertdemo://public/nbdata-20230616.tgz", to="./nbdata.tgz")
EOF

  if [ -f "./nbdata.tgz" ]
  then
    tar xf ./nbdata.tgz -C "${NBDATA_DIR}"
  fi
fi

# clean up
rm -rf ./"${PUB_REPO}"
rm -rf ./nbdata.tgz
