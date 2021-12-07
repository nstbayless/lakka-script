# this script bootstraps a Bayless CD-i
# it must be run on a Lakka device, from any directory.

function assert_has_command {
    if command -v "$1" > /dev/null
    then
        echo "ERROR: command '$1' not found. Aborting."
        exit 1
    fi
}

echo "checking for pre-requisites..."
assert_has_command mktemp
assert_has_command wget
#assert_has_command curl
assert_has_command bash

set -e
SETUP_DIRECTORY=`mktemp -d --suffix=bayless-cdi-bootstrap`
cd $SETUP_DIRECTORY
echo "using '$SETUP_DIRECTORY' as temporary workspace"

wget -O busybox.tar.bz2 https://busybox.net/downloads/busybox-1.33.2.tar.bz2
#curl -o busybox.tar.bz2 https://busybox.net/downloads/busybox-1.33.2.tar.bz2

if [ ! -d .git ]
then
    
fi