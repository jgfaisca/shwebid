#
#!/bin/bash
#
##
## DESCRIPTION: Use OpenSSL to generate a WebID
##
## UID example:
## http://example.com/people/<NICKNAME>
##
## AUTHOR: Jose Faisca
##
## DATE: 2013.11.1
##
## VERSION: 0.1
##


function parse(){
# Read in template file and replace variables
# Usage: parse template_file > outputfile
while IFS='' read -r line; do
    line=${line//\"/\\\"}
    line=${line//\`/\\\`}
    line=${line//\$/\\\$}
    line=${line//\\\${/\${}
    eval "echo \"$line\"";
    done < ${1}
}

function usage(){
  echo -e "usage: $0 args"
  echo -e " -b | --bits arg         bits for encryption"
  echo -e "                         default = $DBITS bits"
  echo -e " -c | --cn arg           common name (CN)"
  echo -e "                         YOUR name
  echo -e " -d | --days arg         how long to certify for"
  echo -e "                         default = $DDAYS days"
  echo -e " -m | --email arg        User e-mail address"
  echo -e " -n | --nick arg         Username/Nick"
  echo -e " -o | --output arg       output directory"
  echo -e "                         default = $OUT"
  echo -e " -p | --password arg     password for encryption"
  echo -e "                         no encription by default"
  echo -e " -u | --uid arg          user identifier (UID)"
  echo -e "                         example http://www.example.com/foaf.rdf#me"
  echo -e " -h | --help             print help\n"
}


UIDENTIFIER=""                  # User Identifier (UID)
UNAME=""                        # Username/Nick
OUT="./output/"                 # Default output directory
ENCRIPT="no"                    # Encript keys (yes/no)
DDAYS="365"                     # How long to certify for
DBITS="2048"                    # Default bits
DEFAULTPWD=""                   # Default password
SCRIPTNAME=${0##*/}             # Script file
CN=""                           # Common Name
FNAME=""                        # First Name
SNAME=""                        # Surname
EMAIL=""                        # e-mail
EMAILSHA1=""                    # e-mail sha1 sum
DATE=$(date +"%Y-%m-%d")        # Date
HOST=$(hostname)                # Host
MODULUS=""                      # Modulus
EXPONENT=""                     # Exponent

while [ $# -gt 0 ]; do
  case "$1" in
    -b|--bits)
            DBITS="$2"
            shift
            ;;
    -c|--cn)
            CN="$2"
            shift
            ;;
    -d|--days)
            DDAYS="$2"
            shift
            ;;
    -e|--email)
            EMAIL="$2"
            shift
            if [[ ! $EMAIL == ?*@?*.?* ]] ;then
                echo "invalid email"
                usage; exit 1
            fi
            ;;
    -n|--nick)
            UNAME="$2"
            shift
            ;;
    -o|--output)
            OUT="$2"
            shift
            ;;
    -p|--password)
            DEFAULTPWD="$2"
            ENCRYPT="yes"
            shift
            ;;
    -u|--uid)
            UIDENTIFIER="$2"
            shift
            # control UID input
            if [[ ! $UIDENTIFIER =~ ^http://*|^https://* ]] ;then
                echo "invalid UID"
                usage; exit 1
            fi
            ;;
    -h| --help)
            usage; exit 1
            ;;
            *)
            echo -e "uknown option $1"
            usage; exit 1
  esac
  shift
done

# control UID
if [ -z "$UIDENTIFIER" -a "$UIDENTIFIER" = "" ]; then
    echo -e "missing UID argument"
    usage; exit 1
fi

# get nick from URI
if [ -z "$UNAME" -a "$UNAME" = "" ]; then
    UNAME="${UIDENTIFIER##*/}"
    UNAME="${UNAME%%.*}"
    UNAME="${UNAME%%#*}"
fi

# get first name from CN
FNAME=$(echo $CN | cut -d' ' -f1)
# get surname from CN
SNAME=$(echo $CN | cut -d' ' -f2-)
SNAME=${SNAME##* }
# get email sha1 sum
EMAILSHA1=$(echo -n $EMAIL | openssl sha1)

# files variables
cert="$UNAME-webid.pem"         # User certificate file
pfx="$UNAME.p12"                # PKCS12 file
cfgtpl="template.cfg"         	# OpenSSL template configuration file
cfg="$UNAME-openssl.cfg"        # OpenSSL configuration file
rdftpl="template.rdf"           # RDF template file
rdf="$UNAME.rdf"                # RDF output file

# control OpenSSL template file
if [ ! -f $cfgtpl ]; then
   echo "the file $cfgtpl does not exist!"
   echo -e "EXIT..\n"; exit 1
fi

# control RDF template file
if [ ! -f $rdftpl ]; then
   echo "the file $rdftpl does not exist!"
   echo -e "EXIT..\n"; exit 1
fi

# control if default output directory exist.
if [ ! -d "$OUT" ];then
   mkdir -v $OUT
fi

# remove exixting files
$(rm -fv $OUT$UNAME-*.*)

# creating OpenSSL configuration file
# parse template file and replace variables
parse $cfgtpl > $OUT$cfg

if [ ! -f $OUT$cfg ]; then
   echo "error creating file $OUT$cfg"
   echo -e "EXIT..\n"; exit 1
fi

# generate a PEM self-signed certificate file that contains the SAN
echo $(openssl req -new -x509 -batch -config $OUT$cfg -out $OUT$cert \
-pubkey -extensions req_ext -keyout $OUT$cert -passout pass:$DEFAULTPWD)

# check certificate file
if [ ! -f $OUT$cert ]; then
   echo "error creating file $OUT$cert"
   echo -e "EXIT..\n"; exit 1
fi

# convert pem to p12
$(openssl pkcs12 -export -clcerts -name "$UNAME" -in $OUT$cert \
-inkey $OUT$cert -out $OUT$pfx -passin pass:$DEFAULTPWD -passout pass:$DEFAULTPWD)

# check p12 file
if [ ! -f $OUT$pfx ]; then
   echo "error creating file $OUT$pfx"
   echo -e "EXIT..\n"; exit 1
fi

# get exponent
EXPONENT=$(openssl rsa -in $OUT$cert -pubin -noout -text | grep Exponent | cut -d" " -f2)

# get modulus from certificate
MODULUS=$(openssl x509 -in $OUT$cert -modulus -noout | sed 's/Modulus=//g' |
sed 's/ //g' | tr '[:upper:]' '[:lower:]')


# create RDF file
# parse template and replace variables
parse $rdftpl > $OUT$rdf

# check RDF file
if [ ! -f $OUT$rdf ]; then
  echo "error creating file $OUT$rdf"
  echo -e "EXIT..\n"; exit 1
fi

echo "Username/Nick = $UNAME"
echo "Common Name = $CN"
echo "e-mail = $EMAIL"
echo "UID = $UIDENTIFIER"
echo "WebID certificate file = $OUT$cert"
echo "PKCS12 file = $OUT$pfx"
echo "RDF file = $OUT$rdf"
echo "Password = $DEFAULTPWD"
echo -e "...\n"

exit 1
