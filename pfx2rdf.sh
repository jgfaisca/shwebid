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
DATE=$(date +"%Y-%m-%d")	# Date
HOST=$(hostname)            	# Host
cert="$FILENOEXT-cert.pem"	# Certificate file
key="$FILENOEXT-key.pem"	# Private key file
rdf=""                      	# RDF file
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
EMAILSHA1=$(echo -n $EMAIL | sha1sum | awk '{print $1}')
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

# create file
echo "creating file $rdf ..."
cat > $rdf << EOF
<?xml version="1.0" encoding="UTF-8"?>
<rdf:RDF
	xmlns:air="http://www.daml.org/2001/10/html/airport-ont#"
        xmlns:con="http://www.w3.org/2000/10/swap/pim/contact#"
        xmlns:dc="http://purl.org/dc/elements/1.1/"
        xmlns:foaf="http://xmlns.com/foaf/0.1/"
        xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
        xmlns:owl="http://www.w3.org/2002/07/owl#"
        xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
        xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
        xmlns:vCard="http://www.w3.org/2001/vcard-rdf/3.0#"
        xmlns:sioc="http://rdfs.org/sioc/ns#"
        xmlns:bio="http://purl.org/vocab/bio/0.1/"
        xmlns:admin="http://webns.net/mvcb/"
        xmlns:rss="http://purl.org/rss/1.0/"
        xmlns:rel="http://purl.org/vocab/relationship/"
        xmlns:cert="http://www.w3.org/ns/auth/cert#"
        xmlns:rsa="http://www.w3.org/ns/auth/rsa#">
<foaf:PersonalProfileDocument rdf:about="">
  <foaf:maker rdf:resource="http://zekaf.github.io/shwebid/"/>
  <foaf:primaryTopic rdf:resource="#me"/>
</foaf:PersonalProfileDocument>
<foaf:Person rdf:about="#me">
  <foaf:nick>${UNAME}</foaf:nick>
  <foaf:name>${CN}</foaf:name>
  <foaf:firstName>${FNAME}</foaf:firstName>
  <foaf:surname>${SNAME}</foaf:surname>
  <foaf:mbox_sha1sum>${EMAILSHA1}</foaf:mbox_sha1sum> 
  <foaf:homepage rdf:resource="${SAN}"/>
  <cert:key>
  <cert:RSAPublicKey>
	<rdfs:label>Made on ${DATE} on ${HOST} using shell script ${SCRIPTNAME} </rdfs:label>
	<cert:modulus rdf:datatype="http://www.w3.org/2001/XMLSchema#hexBinary">${MODULUS}</cert:modulus>
	<cert:exponent rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">${EXPONENT}</cert:exponent>
  </cert:RSAPublicKey>
</cert:key>
</foaf:Person>
</rdf:RDF>
EOF

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
