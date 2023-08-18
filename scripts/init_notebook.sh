#!/bin/bash

# This script initializes the user's notebook home directory

NB_USER=$1
NB_UID=$2
UPSTREAM_TOKEN=$3

#Create required files and directories
if [ ! -d "/home/${NB_USER}/.local" ]
then
  mkdir -p /home/${NB_USER}/.local
  mkdir -p /home/${NB_USER}/.datalab
  mkdir -p /home/${NB_USER}/.notebooks
  chmod 777 /home/${NB_USER}/.local
  chown ${NB_UID}:users /home/${NB_USER}/.local
  chown ${NB_UID}:users /home/${NB_USER}/.datalab
  chown ${NB_UID}:users /home/${NB_USER}/.notebooks
fi

# create symlink to notebooks-latest
# N.B. the -fn arguments are important, as they remove the symlink if
# already present. Without those arguments the symlink will be created
# again inside the previous symlink and because this is run as root
# the symlink will succeed and became are recursive symlink inside
# /mnt/shared/notebooks-latest itself.
ln -sfn /mnt/shared/notebooks-latest /home/${NB_USER}/notebooks-latest
chown -h ${NB_UID}:users /home/${NB_USER}/notebooks-latest

echo ${UPSTREAM_TOKEN} > /home/${NB_USER}/.datalab/id_token.${NB_USER}
chown ${NB_UID}:users /home/${NB_USER}/.datalab/id_token.${NB_USER}

read -r -d  '' config<<EOF
[datalab]
created = `date +"%Y-%m-%d %H:%M:%S"`
[login]
status = loggedin
user = ${NB_USER}
authtoken = ${UPSTREAM_TOKEN}
[auth]
profile = default
svc_url = https://datalab.noirlab.edu/auth
[query]
profile = default
svc_url = https://datalab.noirlab.edu/query
[storage]
profile = default
svc_url = https://datalab.noirlab.edu/storage
[vospace]
mount =
EOF

# if .dl.conf already exists don't overwrite it
if [ ! -f "/home/${NB_USER}/.datalab/dl.conf" ]
then
  echo -e "$config" > /home/${NB_USER}/.datalab/dl.conf
  chown ${NB_UID}:users /home/${NB_USER}/.datalab/dl.conf
fi

# if .bashrc already exists don't overwrite it
if [ ! -f "/home/${NB_USER}/.bashrc" ]
then
  cp -p /mnt/shared/scripts/users_bashrc /home/${NB_USER}/.bashrc
  echo ". ./.bashrc" > /home/${NB_USER}/.profile
  chown ${NB_UID}:users /home/${NB_USER}/.bashrc
  chown ${NB_UID}:users /home/${NB_USER}/.profile
fi

cp -p /mnt/shared/scripts/notebook_container_motd /etc/motd

chown ${NB_UID}:users /home/${NB_USER}
