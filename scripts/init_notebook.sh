#!/bin/bash

# This script initializes the user's notebook home directory

NB_USER=$1
NB_UID=$2
UPSTREAM_TOKEN=$3

#Create required files and directories
mkdir /home/${NB_USER}/.local
mkdir /home/${NB_USER}/.datalab
mkdir /home/${NB_USER}/.notebooks
mkdir /home/${NB_USER}/jupyterhub-singleuser
chmod 777 /home/${NB_USER}/.local
ln -s /mnt/shared/notebook-latest /home/${NB_USER}/notebook-latest
echo ${UPSTREAM_TOKEN} > /home/${NB_USER}/.datalab/id_token.${NB_USER}

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
fi

# if .bashrc already exists don't overwrite it
if [ ! -f "/home/${NB_USER}/.bashrc" ]
then
  cp -p /mnt/shared/scripts/users_bashrc /home/${NB_USER}/.bashrc
  echo ". ./.bashrc" > /home/${NB_USER}/.profile
fi

cp -p /mnt/shared/scripts/notebook_container_motd /etc/motd

chown -R ${NB_UID}:users /home/${NB_USER}
