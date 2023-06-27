#!/bin/bash

## Set variables
PLATFORM=$(python scripts/get_platform.py)
# Search specific python bin and lib folders to compile against the poetry env
PYTHONHOME=$(which python)
#PYTHONHOME=/usr/lib/python3.10

#PYTHONPATH=$(python -c 'import sys; print([x for x in sys.path if "site-packages" in x][0]);')
#PYTHONPATH=/home/ibr/.local/lib/python3.10/site-packages
PYTHONPATH=/usr/include/python3.10
PYTHON_INCLUDE=/usr/include/python3.10
# Give user feedback
echo -e "Running bazel with:\n\tPLATFORM=$PLATFORM\n\tPYTHONHOME=$PYTHONHOME\n\tPYTHONPATH=$PYTHONPATH\n\tPYTHON_INCLUDE=$PYTHON_INCLUDE"

# Compile code
bazel build src/python:pydp \
--config $PLATFORM \
--verbose_failures \
--action_env=PYTHON_BIN_PATH=$PYTHONHOME \
--action_env=PYTHON_LIB_PATH=$PYTHONPATH \
--action_env=PYTHON_INCLUDE=$PYTHON_INCLUDE


# Delete the previously compiled package and copy the new one
rm -f ./src/pydp/_pydp.so
cp -f ./bazel-bin/src/bindings/_pydp.so ./src/pydp
