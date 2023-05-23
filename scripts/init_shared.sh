#!/bin/bash


# public repo supporting jupyterhub-tf terraform scripts

PUB_REPO="jupyterhub-tf-pub"

#shared directory
TGT_DIR="/mnt/pvc/datalab/shared"

# create shared dir if not present
if [ ! -d "$TGT_DIR" ]
then
 mkdir -p $TGT_DIR
fi

# if notebooks-latest is present get a new one
if [ -d "${TGT_DIR}/notebooks-latest" ]
then
  rm ${TGT_DIR}/notebooks-latest
fi

git clone https://github.com/astro-datalab/notebooks-latest.git ${TGT_DIR}/notebooks-latest

# if supporting repo not present get it from github
if [ ! -d "$PUB_REPO" ]
then
  git clone --depth 1  https://github.com/astro-datalab/${PUB_REPO}.git
fi

# copy what's needed to the shared directory
cp -pr ./${PUB_REPO}/scripts ${TGT_DIR}/

# clean up
rm -rf ./${PUB_REPO}
