# Setup of Project

## Directory Structure

Try to store the CuPBoP and Vortex repo's in a single directory, in this case `/Project`. By doing so, your directory structure should look something like:

`/Project` <br>
-----> `/CuPBoP` <br>
-----> `/vortex` <br>
-----> `env_setup.sh`<br>

Take a look at the next section below to understand what `env_setup.sh` is.

## Environment Setup

In Linux-based environments, environment variables are only available for the terminal you used to set them up. Because of this, you have to set up the environment variables for every new terminal you use if you want to do actions like running a benchmark. If you use the Kia/Volvo server, you need to set the environment variables everytime you ssh into one of the servers. 

Create a new file with name `env_setup.sh` and put in the directory containing the `/CuPBoP` and `/vortex` directories, like in the directory structure above. Then copy the below section and paste it into the file.

```bash

# Note: Find the path to Project/ directory (or the directory that holds CuPBoP/ and Vortex/)
#       and copy the path to CuPBoP_PATH and VORTEX_HOME variable in "[pathToProjectDir]"

#       If you use Kia or Volvo server, the path might be "/nethome/[gtUsername]/Project"

export CuPBoP_PATH=[pathToProjectDir]/CuPBoP
export TOOLDIR=/software/vortex-toolchain-2025-06-08
export VORTEX_HOME=[pathToProjectDir]/vortex
export LLVM_VORTEX=$TOOLDIR/llvm-vortex

source $CuPBoP_PATH/CuPBoP_env_setup_wo_PoCL.sh
source $CuPBoP_PATH/CuPBoP_env_setup_wo_PoCL.sh

export VORTEX_ARCHITECTUE=64

export LLVM_PREFIX=$TOOLDIR/llvm-vortex

```

Everytime you need to set up the environment variables, change directory to Project and then run `source env_setup.sh`.
