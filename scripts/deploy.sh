#!/bin/bash

# Version: 20230613
# Author: Chadd Myers <chadd.myers@noirlab.edu>
#
# Replaces the target directory contents (target_dir) with the source from the
# provided public git repository (source_repo).
#
set -e

############################################################
# Parse Options                                            #
############################################################
BRANCH=""

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
                target-dir)
                    TARGET="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
                    ;;
                tmp-dir)
                    TMP_ARG="${!OPTIND}"; OPTIND=$(( $OPTIND + 1 ))
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

if [[ $1 == "-h" ]] || [[ $1 == "-help" ]] || [[ $1 == "--help" ]]
then
  echo "Usage: $0 [OPTIONS] --source SOURCE --target-dir TARGET
  
  Replaces the target directory contents (target_dir) with the source from the
  provided public git repository (source_repo).

  --name                    the unique name of the content or service
  --source                  the public git repository URL
  --branch                  the branch of the repository to use (if other than default branch)
  --target-dir              the target deployment local directory
  --tmp-dir                 the root temp directory (defaults to /tmp)
  -h,--help                 display this help and exit
  "
  exit 0
fi

# parse and validate the various arguments
TMPDIR="${TMP_ARG:=/tmp}"


############################################################
# Main                                                     #
############################################################

# ensure the required directories exist
if [[ -z "${NAME}" ]] || [[ -z "${SOURCE}" ]] || [[ -z "${TARGET}" ]]; then
  echo "The 'name', 'source_repo' and 'target_dir' arguments are required";
  $0 --help
  exit 1
fi

if [ ! -d $TARGET ]
then
    echo "Error: target directory $TARGET does not exist."
    exit 1
fi

if [ ! -d $TMPDIR ]
then
    echo "Error: tmp directory $TMPDIR does not exist."
    exit 1
fi

# prepare some useful variables for later
echo "Loading source from '${SOURCE}' into '${TARGET}' using temp directory '${TMPDIR}'"
TIMESTAMP=`date "+%Y%m%d-%H%M%S"`
TMP_TARGET=$(mktemp -d /tmp/$NAME-auto-"$TIMESTAMP"XXXX)

# create the directory
mkdir -p $TMP_TARGET

# try to load from the repository
echo "Trying to clone $SOURCE into $TMP_TARGET"
cd "$TMP_TARGET"
git clone $SOURCE .
if [[ $BRANCH ]]; then
  git checkout "$BRANCH"
fi

# remove .git directory
echo "Removing git directory from $TMP_TARGET"
rm -rf $TMP_TARGET/.git*

# move the current deployment to a rollback location
ROLLBACK_DIR="$TMPDIR/$NAME-rollback"
rm -rf $ROLLBACK_DIR
echo "Moves current target directory to rollback"
mkdir -p $ROLLBACK_DIR
set +e
cp -pa $TARGET/* $ROLLBACK_DIR
set -e

# deploy the new directory
echo "Deploying new directory"
cp -pa $TMP_TARGET/* $TARGET

# clean up temp directory
echo "Cleaning up $TMPDIR directory"
rm -rf $TMP_TARGET

echo "Succesfully deployed to $TARGET, rollback directory created $ROLLBACK_DIR."
exit 0