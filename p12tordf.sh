#!/bin/bash
# 
##
## FILE: p12tordf.sh
##
## DESCRIPTION: Use openssl to extract modulus and exponente from p12 certificate 
## and create user rdf profile
##
## AUTHOR: Jose Faisca
##
## DATE: 2013.11.1
## 
## VERSION: 0.1
##
## USAGE: ./p12tordf.sh <inputfile.p12>
##

if [ -z "$1" ];then
    echo "Usage: $0 <inputfile.p12>" 
    exit 1
fi

p12=$1
cert="cert.pem"
key="key.pem"
tmp1="person.0"
MODULUS=""
EXPONENT=""
CN=""
FNAME=“”
SNAME=“”
EMAIL=""

# remove files
rm -fv $cert
rm -fv $key
rm -fv $tmp1

# get cert pem
$(openssl pkcs12 -in $p12 -clcerts -nokeys -out $cert)

# get public key 
$(openssl x509 -pubkey -in $cert -noout > $key)

# get exponent
EXPONENT=$(openssl rsa -in $key -pubin -noout -text | grep Exponent | cut -d" " -f2)

# get modulus
MODULUS=$(openssl x509 -in $cert -modulus -noout | sed 's/Modulus=//g' |
sed 's/ //g' | tr '[:upper:]' '[:lower:]')

# get email
EMAIL=$(openssl x509 -in $cert -email -noout)
 
# get CN
CN=$(openssl x509 -in $cert -noout -subject -nameopt multiline |
grep commonName | cut -d'=' -f2 | sed -e 's/^ *//g' -e 's/ *$//g')

# get Firstname
FNAME=$(echo $CN | cut -d" " -f1)

# get Surname
SNAME=$(echo $CN | cut -d" " -f2-)


# create file
echo "creating file person.rdf ..." 
cat > person.0 << EOF
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
    <dc:title>${CN}, (FOAF Profile)</dc:title>
    <dc:description> </dc:description>
    <foaf:maker rdf:resource=""/>
    <foaf:primaryTopic rdf:resource="#"/>
    <admin:errorReportsTo rdf:resource=""/>
    <dc:date> </dc:date>
</foaf:PersonalProfileDocument>

<!-- Me -->

<foaf:Person rdf:about="#">

    <foaf:name>${CN}</foaf:name>
    <foaf:firstName>${FNAME}</foaf:firstName>
    <foaf:surname>${SNAME}</foaf:surname>
    <foaf:gender> </foaf:gender>
    <foaf:mbox rdf:resource="${EMAIL}"/>
    <!-- <foaf:mbox_sha1sum> </foaf:mbox_sha1sum> -->

    <foaf:birthday> </foaf:birthday>
	<bio:event>
		<bio:Birth>
			<bio:date> </bio:date>
			<bio:place> </bio:place>
		</bio:Birth>
	</bio:event>

	<bio:olb xml:lang="en"> </bio:olb>
	<bio:keywords> </bio:keywords>

	<foaf:interest rdf:resource=""/>

    <foaf:depiction dc:description="" rdf:resource=""/>

    <foaf:homepage>
        <foaf:Document rdf:about=""> 
            <dc:title> </dc:title>
            <rdfs:seeAlso> 
                <rss:channel rdf:about="">
                    <dc:title> </dc:title>
                </rss:channel>
            </rdfs:seeAlso> 
        </foaf:Document> 
    </foaf:homepage>

    <!-- Online Accounts SNS -->

    <foaf:holdsAccount>
    	<foaf:OnlineAccount>
            <foaf:accountServiceHomepage rdf:resource=""/>
            <foaf:accountName> </foaf:accountName>
            <foaf:homepage rdf:resource="" rdfs:label=""/>
        </foaf:OnlineAccount>
    </foaf:holdsAccount>
    
    <!-- Social Network -->

	<foaf:knows rdf:resource="" />

    <!-- Projects -->

	<foaf:currentProject rdf:resource=""/>
	<foaf:pastProject rdf:resource=""/>
	
    <!-- additional Feeds -->

    <rdfs:seeAlso>
        <rss:channel rdf:about="">
        	<dc:title> </dc:title>
        	<dc:description> </dc:description>
        </rss:channel>
    </rdfs:seeAlso>

    <!-- certificate -->

    <cert:key>
        <cert:RSAPublicKey>
            <rdfs:label>Made by shell script</rdfs:label>
            <cert:modulus rdf:datatype="http://www.w3.org/2001/XMLSchema#hexBinary">${MODULUS}</cert:modulus>
            <cert:exponent rdf:datatype="http://www.w3.org/2001/XMLSchema#integer">${EXPONENT}</cert:exponent>
        </cert:RSAPublicKey>
    </cert:key>

</foaf:Person>

</rdf:RDF>
EOF

# check rdf file
if [ -f person.0 ]; then
  cp person.0 person.rdf
  echo "file person.rdf sucessfuly created!" 	
else 
  echo "error creating file person.rdf"; exit 1
fi

echo ...
echo EXIT..

exit 1
