#
#!/bin/bash
#
##
## DESCRIPTION: Use openssl to extract modulus and exponent
## from a PKCS#12/PFX file and create the user RDF file.
## PFX files usually have extensions such as .pfx and .p12. 
##
## AUTHOR: Jose Faisca
##
## DATE: 2013.11.1
##
## VERSION: 0.2
##

function parse(){
# Read in template file and replace variables
# Usage: parse <template_file>
while IFS='' read -r line; do
    line=${line//\"/\\\"}
    line=${line//\`/\\\`}
    line=${line//\$/\\\$}
    line=${line//\\\${/\${}
    eval "echo \"$line\"";
    done < ${1}
}

if [ -z "$1" ];then
   echo "Usage: $0 <PKCS#12/PFX file>"
   echo "EXIT.."; exit 1
fi

# get input file name without extension
pfx=$1
FILENAME=${pfx##*/}
FILENOEXT=${FILENAME%.*}
#FILEEXTENSION=${pfx##*.}
#BASEDIRECTORY=${pfx%$FILENAME}

if [ ! -f $pfx ]; then
   echo "the file '$pfx' does not exist!"
   echo "EXIT.."; exit 1
fi

SCRIPTNAME=${0##*/}         	# Script file
DATE=$(date +"%Y-%m-%d")        # Date
HOST=$(hostname)            	# Host
cert="$FILENOEXT-cert.pem"      # Certificate file
key="$FILENOEXT-key.pem"        # Private key file
rdftpl="template.rdf"           # RDF template file
rdf=""                      	# RDF output file
MODULUS=""                  	# Modulus
EXPONENT=""                 	# Exponent
CN=""                       	# Common Name
FNAME=""                    	# First Name
SNAME=""                    	# Surname
EMAIL=""                    	# e-mail
EMAILSHA1=""                	# e-mail sha1 sum
SAN=""                      	# Subject Alternative Name
UNAME=""                    	# Username/Nick

# remove existing cert file
if [ -f $cert ]; then
   rm -fv $cert
fi

# remove existing key file
if [ -f $key ]; then
   rm -fv $key
fi

# get cert pem
$(openssl pkcs12 -in $pfx -clcerts -nokeys -out $cert)
# get public key
$(openssl x509 -pubkey -in $cert -noout > $key)
# get exponent
EXPONENT=$(openssl rsa -in $key -pubin -noout -text | grep Exponent | cut -d" " -f2)
# get modulus
MODULUS=$(openssl x509 -in $cert -modulus -noout | sed 's/Modulus=//g' |
sed 's/ //g' | tr '[:upper:]' '[:lower:]')
# get email
EMAIL=$(openssl x509 -in $cert -email -noout)

if [[ "$OSTYPE" == "darwin"* ]]; then
    EMAILSHA1=$(echo -n $EMAIL | shasum -a 1 | awk '{print $1}')
else
    EMAILSHA1=$(echo -n $EMAIL | sha1sum | awk '{print $1}')
fi

# get CN (Common Name)
CN=$(openssl x509 -in $cert -noout -subject -nameopt multiline |
grep commonName | cut -d'=' -f2 | sed -e 's/^ *//g' -e 's/ *$//g')
# get Firstname
FNAME=$(echo $CN | cut -d" " -f1)
# get Surname
SNAME=$(echo $CN | cut -d" " -f2-)
# get SAN 
SAN=$(openssl x509 -in $cert -noout -text | grep URI: | cut -d":" -f2-)
# get Username/Nick
UNAME=${SAN##*/}
# set RDF output file name 
rdf="$UNAME.rdf"

# remove existing RDF file
if [ -f $rdf ]; then
   rm -fv $rdf
fi

# parse RDF template file and replace variables
echo "creating file $rdf ..."
parse $rdftpl > $rdf

# check RDF file
if [ -f $rdf ]; then
  echo "RDF file = $rdf (OK!)"         
else
  echo "error creating file $rdf"; exit 1
fi

echo "WebID = $SAN"
echo "Username/Nick = $UNAME"

echo ...
echo DONE..

exit 1
