export SIMULATOR=dsim
PROJ_ROOT_DIR=$PWD/../../../..
MAKEFILE=setup_dsim.mk

make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR build-unit-test div

make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR build-unit-test divu

make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR firmware-clean
make -f $MAKEFILE PROJ_ROOT_DIR=$PROJ_ROOT_DIR firmware.hex

