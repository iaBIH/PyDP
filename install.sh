# install dev should be installed 

#===============================================
#       Cleaning 
#===============================================
rm -r third_party/differential-privacy
sudo rm -r ~/.cache/bazel
rm bazelisk-linux-amd64
sudo rm src/pydp/_pydp.so
sudo rm pydp
sudo rm -r bazel-bin
sudo rm -r bazel-PyDP
sudo rm -r bazel-testlogs
sudo rm -r bazel-out

#===============================================
#       Define variables 
#===============================================

PYTHON_VERSION=$(python --version)
BAZELISK_VERSION=v1.8.1
BAZELISK_BINARY=bazelisk-linux-amd64
BAZELISK_DOWNLOAD_URL=https://github.com/bazelbuild/bazelisk/releases/download/v1.17.0/bazelisk-linux-amd64

# Set environment variables
export PROJECT_DIR="${HOME}/myGit/PyDP"
export PATH="/root/bin:${PATH}"
export DP_SHA="5e7cf28bf55ebac52fc65419364388c33ebc01a4"

# Define working directory
WORKDIR="${HOME}/myGit/PyDP"


#===============================================
#       download install prerequests
#===============================================
# Install apt-get packages
sudo apt update && \
    sudo apt -y install \
    wget \
    zip \
    git \
    software-properties-common \
    gcc \
    g++ \
    clang-format \
    build-essential \
    python3-distutils \
    pkg-config \
    zlib1g-dev

# checking for g++
dpkg -s g++ &> /dev/null
if [ $? -eq 0 ]; then
    echo "g++ is installed, skipping..."
else
    echo "Installing g++"
    sudo apt-get install g++
fi

# checking for Python 3
echo "Checking for python3 installation"
if command -v python3 &>/dev/null; then
    echo "Python 3 already installed"
    elif command python --version | grep -q 'Python 3'; then
    echo "Python 3 already installed"
else
    echo "Installing Python 3 is not installed"
    sudo apt-get update
    sudo apt-get install python3
fi

# checking for poetry
echo "Checking for poetry"
if python3 -c "import poetry" &> /dev/null; then
    echo "poetry is already installed"
else
    echo "Installing poetry"
    pip3 install poetry
fi

# bazel
if command -v bazel &>/dev/null; then
    echo "Bazel already installed"
else
    echo "Installing Bazel dependencies"
    sudo apt-get install pkg-config zip zlib1g-dev unzip
    wget "${BAZELISK_DOWNLOAD_URL}/${BAZELISK_VERSION}/${BAZELISK_BINARY}" && \
    chmod +x ${BAZELISK_BINARY}
    mv ${BAZELISK_BINARY} $HOME/bin/bazel
    export PATH="$PATH:$HOME/bin"
fi

# clang-format
if command -v clang-format &>/dev/null; then
    echo "clang-format already installed"
else
    echo "installing clang-format"
    sudo apt-get install clang-format
fi

# Downloading the Google DP library
git submodule update --init --recursive


# checkout out to particular commit
cd third_party/differential-privacy && git checkout e59bbcf86a5febcbbe6b2e5ebea37ee52457cf36 && \
cd -
# renaming workspace.bazel to workspace
mv third_party/differential-privacy/cc/WORKSPACE.bazel third_party/differential-privacy/cc/WORKSPACE

# Removing the java part
rm -rf third_party/differential-privacy/java third_party/differential-privacy/examples/java

# Removing the Go part
rm -rf third_party/differential-privacy/go third_party/differential-privacy/examples/go

# Removing the Privacy on Beam  
rm -rf third_party/differential-privacy/privacy-on-beam

#===============================================
#       Installation 
#===============================================
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

# # Delete the previously compiled package and copy the new one
rm -f ./src/pydp/_pydp.so
cp -f ./bazel-bin/src/bindings/_pydp.so ./src/pydp
pip install .
cp src/pydp/_pydp.so ~/.local/lib/python3.10/site-packages/pydp

