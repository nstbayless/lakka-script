# usage:
#
#   bash <(curl -s https://raw.githubusercontent.com/nstbayless/lakka-script/main/bayless-cdi-bootstrap.sh)
#
# this script bootstraps a Bayless CD-i
# it must be run on a Lakka device, from any directory.

if [ ! -d /storage ] || [ ! -f /usr/bin/retroarch ]
then
    echo "ERROR: this script must be run on a Lakka device."
    exit 1
fi

function assert_has_command {
    if ! command -v "$1" > /dev/null
    then
        echo "ERROR: command '$1' not found. Aborting."
        exit 2
    fi
}

echo "checking for pre-requisites..."
assert_has_command mktemp
assert_has_command wget
assert_has_command bash
assert_has_command openssl

set -e
SETUP_DIRECTORY=`mktemp -d`
cd $SETUP_DIRECTORY
echo "using '$SETUP_DIRECTORY' as temporary workspace"

# usage: echo "blah" | $ENCRYPT pass:$PASSWORD | $DECRYPT pass:$PASSWORD
ENCRYPT="openssl aes-256-cbc    -a -iter 6 -pass"
DECRYPT="openssl aes-256-cbc -d -a -iter 6 -pass"

while [ -z "$PASSWORD" ]
do
    echo "Enter Bayless CD-i master password:"
    read PASSWORD
done

# check that password was correct
if ! (echo "U2FsdGVkX193ldYerIk4JvcGPdv3Fz2NLR51g5wY11E=" | $DECRYPT pass:$PASSWORD)
then
    echo "Incorrect password. Please contact administrator for assistance."
    exit 1
fi

REPO_FILE_ACCESS_URL=https://raw.githubusercontent.com/nstbayless/lakka-script/main

#download pre-requisite files
mkdir bin
cd bin
wget $REPO_FILE_ACCESS_URL/bin/git
cd ..

mkdir lib
cd lib
wget $REPO_FILE_ACCESS_URL/lib/libc.so.6
wget $REPO_FILE_ACCESS_URL/lib/libpcre2-8.so.0
wget $REPO_FILE_ACCESS_URL/lib/libpthread.so.0
wget $REPO_FILE_ACCESS_URL/lib/libz.so.1
cd ..

export PATH="$PATH:$SETUP_DIRECTORY/bin"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SETUP_DIRECTORY/lib"