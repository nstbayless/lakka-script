# usage:
#
#   export PASSWORD='<Bayless CD-i master password>' # (optional)
#   curl https://raw.githubusercontent.com/nstbayless/lakka-script/main/bayless-cdi-bootstrap.sh | /bin/bash
#
# this script bootstraps a Bayless CD-i
# it must be run on a Lakka device, from any directory.
# It is supposed to be idempotent, so running it multiple times or
# running it on an already-existant installation is THEORETICALLY OKAY.
#
# Note: master password is NOT the Lakka root password (i.e. 'root'). If you
# have been given this script, then you should know what the password is.

if [ ! -d /storage ] || [ ! -f /usr/bin/retroarch ] || [ ! -d /flash ]
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
    # we need to read from /dev/tty so that this works even during curl-bash
    read PASSWORD < /dev/tty 
done

# check that password was correct
if ! (echo "U2FsdGVkX193ldYerIk4JvcGPdv3Fz2NLR51g5wY11E=" | $DECRYPT pass:$PASSWORD)
then
    echo "Incorrect password. Please contact administrator for assistance."
    echo "To resolve this error, please use the following command before running this script:"
    echo ""
    echo "  export PASSWORD='<Bayless CD-i master password>'"
    echo ""
    exit 1
fi

REPO_FILE_ACCESS_URL=https://raw.githubusercontent.com/nstbayless/lakka-script/main

#download pre-requisite binaries
mkdir bin
cd bin
wget $REPO_FILE_ACCESS_URL/bin/git
chmod a+x git
cd ..

# download pre-requisite libs
mkdir lib
cd lib
wget $REPO_FILE_ACCESS_URL/lib/libpcre2-8.so.0
wget $REPO_FILE_ACCESS_URL/lib/libz.so.1
cd ..

# add binaries and libraries to the PATH
export PATH="$PATH:$SETUP_DIRECTORY/bin"
export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:$SETUP_DIRECTORY/lib"

# add ssh key
cd /storage
mkdir -p .ssh

ENCRYPTED_PUB_KEY="
U2FsdGVkX1+aHNbwiDKY48Os16csBKBY+Yg7fcfNBZisnmS301ehRBW0HliiF/rj
Zh/PrRvsM5MMjchoEx9OBwo5ilTGQW5FV246bbv/D6EhwXXQy2Qnj1NZt9apyZdj
9kvbsrdm252rpqf3q3LRgtm5LUPO7k7OhluDmL0XSDiMHGmcm4K8SREI1K1Jlvaj
IILjRXJAVPKrRh68kBQy166uwFSD/LwSjbn+k0rTCg3cAJBnco7xJG1178GoKlv2
nBwmMEn3jdDYKkB8X6XCdMpVkEZbfXJ942wCz5Rp4WIlpVNz1VNdZF4euc0WJtfF
6ONkwb6Te+Ko9rmT0vaYUjdNVFXdyicBsfJ5wI57zZ37xm9NhkQP7Crqc//vFz55
zfGC0mNkhH2uX4BP1n5SGoDq9RenFwYS/QG7rynMZeNaojWy68vnGLB1Ru85vIx8
UKhtfp0R7KZc5elyIMvGm+piv8ZjyW7+H41hAS0ZRMIyEWJ68rWWmSLE4BgVi0jQ
MPxtKHUkCpuDG+Q2SUWTatBickp58vsfqND2fmXTvHwHgxqDBbOxCo6mSuROAxrq
GbZE00+SDwZ4hbIa4To7kNCxA+h/WW4ciGoqZYiGtBoozS0IhqGv3QU5VFr4UyZB
RF5WP77tdFZzC5E4O7FWr1nCB7xI9cjLzBUYF+hUGLstrKwNnhWQ2mN3MBTHdrzz
2NOLrd0DTVPbOOKW5aJ81oGsx9/VK8hmVr7i/p/0UarzgIvFIUWRdKV2TFqQNsCX
IYOZtnzuJuST7EsZMNagXQ==
"

ENCRYPTED_PRIV_KEY="
U2FsdGVkX18h0y6XtIrpY69xVQaUpP58gHi4hYYYajyB0op53LFalo3hM/gPb1g4
tmXxEVISGy82nQxQWt6UkapegqlSnOkyBjcH/eHxrH9e7wd9ezHfmLrmuYEfnTaW
S1nZjjjIWwwz9JnCPAsj+zM6AmfTtjjHvOBDwsmCo3Vp+FbtXLLFIcRYomkULGN/
rgdgTocaCEnaKAJ/XWvgolf7NQ2Ts+5XinOrQ9QzePc1EJM2VQDTrsoMK7iS5Net
rq52sXXSlStLwFdknZUzE7d3sUDoxYF5EfrjXx4UQG8CYaetvpDRdZxqP1G/3usu
7aYZv7S9yT0jcJk2I10K+Q+zBHXgci0vkUQnzzDI61LnFJM3tx+nKzq2yl0c+Sfd
UGIa68iSA35kIgVQt8WnluGrLeh1iVizHjHqabW4OQUG/AfhlMYaW7pVK5tCBZ8j
8qMpk7jeIBQ1njndW6JBQlfeCnr2BLsUc931nOk66ZCJLE/eYhcxbSS4taIIoCl+
5ZI9O4IYsI34pvUYMXbDwC21DhxEgZ9nnnCoHzigbNw0quzyND8cXwUKG5witE/V
ZothRrbrhPdT1mcOuAO9iDTWL8aDrPLFP3C1mrkxWxZuTSZausZLXHhzlRxH+dD+
xN2Qt32P4jyJgDP8gDErPFYh75ZEuRnmv6QIx6Raz/5hjr4DN31MEjY/aU5A13Ia
xZWckU7G9ENVQWE9/C0zSZETk/YmuecplwGjkvl61qH9RRXmcTl5YM/HG7Er3Upr
7aqfjtlBRqCTJ2G8dtzu1OuVcspovx7rGHPekOhrGFABOZts2b6XPopVeYtH2awi
R6ADl9ISpujKAIuKChFxSODSj0kY2fHQuGz+YFql3FbDYjNYhbNwhGwI9sQD+I7U
6QncU4vjc0eD+qEr7XAqRbgj43T8nn9zEkvaif+gcSgC0+yPHlpy+MB6BU3bqAqa
cxA4zl7g07Vf468CNcrwaqebA36izK6RRf1j2vsm5WvTZow5YolCcZ46Y5CQHhFr
iIx8EloAS77gRQZwXfTPQV7QE/EF2Fli97cpWZMtqGrmbuYbTxf/ZQ8e7/zBwf6y
E7R9n+KUAMLqxPeMWAP3bOlhRa+Wmy7B/LWlewijuIJp+sRYE/PMX1iMemeQpO+r
lUgPwq3vwAzujbXfBMM5t1Im+sElmUe/52z1lN/kaxEgX7v7lMMW6Cm50XdSMUK6
Flgt2saEaLC62O+5PGlhkgMpu0cwjfINTzXtnPmxVGt/H3+ZUN+So0YK5lU1Jgqw
AMCamIsd0xqNcIFYUhqAby0f8PP8q+4R5L7c122vE+69K7R5Ps7u4F9102osy00X
ty6WMQjNTI2/24+OfiE2CvYicRhQmorY8f70mj/r8tykcz485aCEmsMSbYxWE6UC
o303BU6HqUyDvXHqQ8eD8a8R6VCWZX/dKE656D3CEBJXnhFMpSFtjlnqtqOnSBdA
thLciq3c3Ryluj0v+dgqnPfcyIfr9G8/lIahtZM5ClKkSoeUqkqwImSdKgSl4w5v
Lwo6GAcVziA6dGV/zKNdD9V5KGbpr5708DNx+5CefGpWKOowjIQ8tN0+dbpn70CP
lHhXlucBOQpXMOhNt2QIwT/rnQwHLsqS9tDZEkCjwUHq5xOZwg/S6AGyihquEluD
O7pLx8nGxAL1kjnZcUm9m8KxIsNIP3XQ7xUOHQ9Qiq9sNN0zsdCpKCKkkwviaTyS
yW2IqXD97HBU7KiTX79KvTMXxW1sIDyI5xGi42PbRH8esRh7WFNW7QlBUKUPsEuL
CgMwn0iYn6GIUJDD0ySXGV79JQvw8zfRqGXWCv/Y7UJSJHSpscP+TzrIz56Il+uR
z32q2ZgPLVB4t8LzhdhCHELFKJOSLOfHkElILDRojUOWbwmcOwYs9jp8icGFqx2W
G4DnzEhvplSTokwvJyhmMWzzXcu9Eu9VFtGzsQ4xHtNveKGLgz8FtkrZuACalFvV
d61N3Ah3DsrSpx0B4adSUo0M5C53lyY6/rWiX/+gID0p2P+M7bx75V6e1IsL+Nha
ydWyjf4DBdP7cy0I54rhW3SKKyu7kGL3mHqcaZaVBnVwe41Fe0o0maLOxzu0wXGN
50vsTxJD5tzOu6TXFaASM+5Uf1mUU0e600hmiTt8WFhm3UePN+74zztKB6stk+T2
GHZrIWlaCGRkdWNfYfyof2r6WzphAuHKuQmsMiXrHeEyzOQwzy3o6EEPLF8o5+k/
M+sbJaOnDZsNYmN3gM5fDH0vE5gFLnX68YsX59K/PbfhgC/oXg5RcaNGBJITMKo6
FjAV8G/7FcmXQFX5Qvhqf+2RC3hsD1NPQEcoeNI/O427zhXHVRAqlZd4qI695QqD
vFTwsRIQSBvv8OHGNMH2dDKvW7G8vA4o635NXo5UE1J/nHa1sFX3cXu25ikhNiSt
MBbCDG94mZz2zo0aPzmz/k3jhAtcmE3oGHgyFip+b9eONXH2FK97m0Bp8aZMs0vY
cTYp/BlxEskNE2rZP4NW6gGUrsy1aG2kv6jE7oOzDS9b5gUVufjg5AYH/mPeecW1
//WduO/JJBpdnrxxb5L9mZ9cu6couSfj8Jm6KZu5tvjpIbuTw2YtL4wjxtnuWIyA
tonI3oTPMfebIUZf12VsWeYPD3wNeyj7G6gKKx2dMMuY95S6WjNcHBSDAbWdaGIq
VQe2EhK6Vv/GxXHzFKrriIE3SKuqFkiN9hbhCDPcMJPRdbAsssjZEInJMrUim1dD
dKNU068itrIUXy+tNt6S1dL3m9Sa7wWzkwKmcas4dclNv8ZRkh6lwPVIdipSiQqk
Y7zPatQa8F7W1YIXkZJ+2TZv04S3wGj7ZemEQALbYR1u+wpLySWrHZLVkJ+uKM2k
yMo4gmnnSN27ScXgoAxxIXRWCK/3aDm7L2zfgeZYd+7sJb1WsPTXYCwur8XOTQbw
2te1Qg17xHxEPSy1T9wjNMLxEpp3Pk76KUvs7/Blxb5Cg7W/lyPj1XhoO8fPPpHG
R7UzvBC7wzGgjkJIsQeed5Huk+6FLWsYYGvXQ3GFKx0xJTEOv2EXesHChqGk6cWn
P3LcrpD03hCywcgMIBFRbRwVBA5owraosqDL2RSti9JC6Uf9cT6GwU1eBMFeryoI
b1hsilKjRDIJzuHYFYz0fIk3WAisgBEM38GWT1wezXqAHaZKuiIQQ9EBSypjYPa9
kNP0YvjL2qNFiPepJPvVGlYrUUkzITzfMTKwIiYG077TZgU2jiB+bZZzN8Hx7K7u
9N4C4lRgqEFbK6LkyA6Un5dhnc+WqEEcrVzL3OFkk+ZCowhPcRTffIVMbN7kVaho
dvJfnxBdeL2+QnwolvPjb4GAfUNc8PkOX5Ckgz5f1RhN016KozVIujvJT8GHbYet
zsM7VlDCD/IYkAMIipA4mn/SrIy7aqPRxX4YXYVXIWfDzXgamafMpT1xuUO3JS3l
XB6z2BU5Cvhc9p28+PfqgEp+lCSVdWC9yJojOY4g77M=
"

echo "$ENCRYPTED_PUB_KEY" | $DECRYPT pass:$PASSWORD > .ssh/id_bayless_cdi_rsa.pub
chmod 644 .ssh/id_bayless_cdi_rsa.pub
chown root .ssh/id_bayless_cdi_rsa.pub
echo "$ENCRYPTED_PRIV_KEY" | $DECRYPT pass:$PASSWORD > .ssh/id_bayless_cdi_rsa
chmod 600 .ssh/id_bayless_cdi_rsa
chown root .ssh/id_bayless_cdi_rsa

echo "added private keys."

# disable strict host checking. Allows git clone to succeed without user input.
# add host, so as to allow using the ssh key
echo "StrictHostKeyChecking no" > .ssh/config
echo "" >>  .ssh/config
echo "Host bayless-cdi-repo" >> .ssh/config
echo "    Hostname github.com" >> .ssh/config
echo "    User git" >> .ssh/config
echo "    IdentityFile ~/.ssh/id_bayless_cdi_rsa" >> .ssh/config

if [ -d .git ]
then
    git remote set-url origin bayless-cdi-repo:nstbayless/bayless-cdi-content.git
else
    git clone bayless-cdi-repo:nstbayless/bayless-cdi-content.git
fi