#!/bin/bash

../deploy.sh \
   --name notebooks-latest \
   --source git@github.com:astro-datalab/notebooks-latest.git \
   --target-dir /usr/src/notebooks-latest