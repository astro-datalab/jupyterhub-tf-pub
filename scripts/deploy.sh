#!/bin/bash

# Version: 20230620
# Author: Chadd Myers <chadd.myers@noirlab.edu>
#
# Replaces the target link with the latest contents of a source repository
# while retaining a certain number of old versions.
#
#  deploy.sh \
#   --name notebooks-latest \
#   --source https://github.com/astro-datalab/notebooks-latest.git \
#   --link-target /usr/notebooks-latest/latest \
#   --work-dir /usr/notebooks-latest/
#
set -e

############################################################
# Display help                                             #
############################################################
if [[ $1 == "-h" ]] || [[ $1 == "-help" ]] || [[ $1 == "--help" ]]
then
  echo "Usage: $0 [OPTIONS] --name NAME --source SOURCE --link-target TARGET --work-dir WORK_DIR

  Generates a new version directory in the working directory (--work-dir) then
  updates the target link (link-target) to use the new version.

  --name                    the unique name of the content or service
  --source                  the public git repository URL
  --branch                  the branch of the repository to use (if other than default branch)
  --work-dir                the directory to use when setting up new versions and rollback locations
  --link-target             location to link the latest deployment to
  --keep-num                The number of previous versions to keep (default is 2)
  -h,--help                 display this help and exit
  "
  exit 0
fi

############################################################
# Parse Options                                            #
############################################################
BRANCH=""
TARGET=""
NAME=""

while getopts ":-:" optchar; do
    case "${optchar}" in
        -)
            case "${OPTARG}" in
                name)
                    NAME="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                source)
                    SOURCE="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                branch)
                    BRANCH="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                link-target)
                    TARGET="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                work-dir)
                    WORK_DIR_ARG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                keep-num)
                    KEEP_NUM_ARG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                *)
                    if [ "$OPTERR" = 1 ] && [ "${optspec:0:1}" != ":" ]; then
                        echo "Unknown option --${OPTARG}" >&2
                        exit;
                    fi
                    ;;
            esac;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done


############################################################
# Main                                                     #
############################################################

WORK_DIR="${WORK_DIR_ARG:=/tmp/deploy}"
mkdir -p $WORK_DIR

# ensure the required directories exist
if [[ -z "${NAME}" ]] || [[ -z "${SOURCE}" ]] || [[ -z "${TARGET}" ]]; then
  echo "The 'name', 'source_repo' and 'target_dir' arguments are required";
  $0 --help
  exit 1
fi

if [ ! -d $TARGET ]
then
    echo "Warning: target link location $TARGET does not exist. A new link will be created"
fi

if [ ! -d $WORK_DIR ]
then
    echo "Error: work directory $WORK_DIR does not exist."
    exit 1
fi
if [[ "$WORK_DIR" == "" ]]; then
    echo "error working directory isn't defined"
    exit 1
fi

# clean up old deployments that might be left
PREV_VERSION_KEEP_NUM="${KEEP_NUM_ARG:=2}"
cd $WORK_DIR
# the line below orders the files by date and keeps the newest files as determined by PREV_VERSION_KEEP_NUM
# adapted from here: https://stackoverflow.com/questions/52551734/how-to-remove-all-directories-except-for-the-last-one
find . -maxdepth 1 -mindepth 1 -type d -printf "%T+ %f\0" | sort -z | head -z -n -$PREV_VERSION_KEEP_NUM | cut -z -d' ' -f 2- | xargs -0 rm -rf
echo "Attempted to clean up old versions, kept the ${PREV_VERSION_KEEP_NUM} latest copies"

# prepare some useful variables for later
TIMESTAMP=`date "+%Y%m%d-%H%M%S"`
BUILD_LOC=$(mktemp -d $WORK_DIR/nblatest-$TIMESTAMP-XXXXXXXX)

# begin the deployment logic
echo "Loading source from '${SOURCE}' into '${TARGET}' using working directory '${WORK_DIR}'"

# try to load from the remote repository
echo "Trying to clone $SOURCE into $BUILD_LOC"
git clone --depth 1 $SOURCE $BUILD_LOC
if [[ $BRANCH ]]; then
    # if a branch was specified then load that branch
    cd $BUILD_LOC
    git checkout "$BRANCH"
fi

# remove .git directory
echo "Removing git directory from $BUILD_LOC"
rm -rf $BUILD_LOC/.git*

# rename the directory and update the symlink
echo "Deploying new directory"
touch $BUILD_LOC
ln -f -s -n $BUILD_LOC $TARGET

echo "Succesfully deployed to $TARGET from $BUILD_LOC"
exit 0