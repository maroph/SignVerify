#!/bin/bash
#
##############################################
# Copyright (c) 2024 by Manfred Rosenboom    #
# https://maroph.github.io/ (maroph@pm.me)   #
#                                            #
# This work is licensed under a MIT License. #
# https://choosealicense.com/licenses/mit/   #
##############################################
#
declare -r SCRIPT_NAME=`basename $0`
declare -r VERSION="${SCRIPT_NAME}  1  (22-MAY-2024)"
#
###############################################################################
#
SCRIPT_DIR=`dirname $0`
#
cwd=`pwd`
if [ "${SCRIPT_DIR}" = "." ]
then
    SCRIPT_DIR=${cwd}
else
    cd ${SCRIPT_DIR} || exit 1
    SCRIPT_DIR=`pwd`
    cd ${cwd} || exit 1
fi
cwd=
unset cwd
#
declare -r SCRIPT_DIR
#
###############################################################################
#
umask 0027
export LANG="en_US.UTF-8"
#
OPENSSL=openssl
#OPENSSL="myopenssl --1.1.1"
#OPENSSL="myopenssl --3.0"
#OPENSSL="myopenssl --3.1"
#OPENSSL="myopenssl --3.2"
#OPENSSL="myopenssl --3.3"
#OPENSSL="myopenssl --dev"
#
pkcs12="pkcs12"
# -legacy is needed for files, created by OpenSSL 1.1.1 or lower
#pkcs12="pkcs12 -legacy"
#
# Openssl 3.x and Legacy Providers
# https://www.practicalnetworking.net/practical-tls/openssl-3-and-legacy-providers/
#
###############################################################################
#
keystoreP12=""
passphrase=""
#
keystoreJKS=""
keystoreP12_NL=""
#
force=0
legacy=0
nopassphrase=0
prefix=""
#
###############################################################################
#
print_usage() {
    cat <<EOT

Usage: ${SCRIPT_NAME} [<options>] <PKCS12 keystore> <passphrase>
       Extract key data from a PKCS12 keystore
       Required: OpenSSL >= 3.0

    Options:
    -h|--help    : show this help text and exit
    -V|--version : show version information and exit
    -f|--force   : overwrite existing PEM files
    -n|--no-passphrase : create unencrypted private key file
    -p|--prefix  : prefix for key/cert files (default: no prefix)
    --legacy     : PKCS12 keystore was created with OpenSSL 1.1.1

    Arguments:
    PKCS12 keystore : PKCS12 keystore file name
    passphrase      : passphrase of the keystore

    Files created:
    - cert.pem    : certificate
    - chain.pem   : signer certificate chain
    - private.pem : encrypted private key
    - public.pem  : public key

    - private_nopassphrase.pem : unencrypted private key
                                 (option -n|--no-passphrase)
    - *.jks             : create a JKS keystore from the given PKCS12 keystore if
                          the Java JDK keytool program is available
    - *_none_legacy.p12 : with option --legacy only:
                          create a new PKCS12 keystore from the given legacy keystore

EOT
}
#
###############################################################################
#
while :
do
    option=$1
    case "$1" in
        -h | --help)    
            print_usage
            exit 0
            ;;
        -V | --version)
            echo $VERSION
            exit 0
            ;;
        -f | --force)
            force=1
            ;;
        -n | --no-passphrase)
            nopassphrase=1
            ;;
        -p | --prefix)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : prefix name missing"
                exit 1
            fi
            prefix="${1}_"
            ;;
        --legacy)
            legacy=1
            pkcs12="pkcs12 -legacy"
            ;;
        --)
            shift 1
            break
            ;;
        --*)
            echo "${SCRIPT_NAME}: '$1' : unknown option"
            exit 1
            ;;
        -*)
            echo "${SCRIPT_NAME}: '$1' : unknown option"
            exit 1
            ;;
        *)  break;;
    esac
#
    shift 1
done
#
###############################################################################
#
if [ "$1" = "" ]
then
    echo "${SCRIPT_NAME}: PKCS12 keystore name missing (*.p12)"
    exit 1
fi
#
if [ ! -r $1 ]
then
    echo "${SCRIPT_NAME}: can't read file $1"
    exit 1
fi
keystoreP12=$1
#
if [ "$2" = "" ]
then
    echo "${SCRIPT_NAME}: passphrase for PKCS12 keystore missing"
    exit 1
fi
passphrase=$2
#
###############################################################################
#
basename=$(basename $1)
base=${basename%.*}
ext=${basename: -4}
## echo "base : ${base}"
## echo "ext  : ${ext}"
## exit 0
#
###############################################################################
#
if [ "${ext}" != ".p12" ]
then
    echo "${SCRIPT_NAME}: the keystore must have the extension .p12"
    exit 1
fi
#
###############################################################################
#
keystoreJKS=${base}.jks
keystoreP12_NL=${base}_none_legacy.p12
#
#echo "keystoreP12    : ${keystoreP12}"
#echo "passphrase     : ${passphrase}"
#echo "keystoreJKS    : ${keystoreJKS}"
#echo "keystoreP12_NL : ${keystoreP12_NL}"
#exit 0
#
###############################################################################
#
if [ ${force} -eq 1 ]
then
    rm -f ${prefix}cert.pem ${prefix}chain.pem ${prefix}private*.pem \
          ${prefix}public*.pem ${prefix}private_nopassphrase.pem
fi
#
if [ -f ${prefix}cert.pem ]
then
    echo "${SCRIPT_NAME}: file ${prefix}cert.pem already exist"
    exit 1
fi
#
if [ -f ${prefix}chain.pem ]
then
    echo "${SCRIPT_NAME}: file ${prefix}chain.pem already exist"
    exit 1
fi
#
if [ -f ${prefix}private.pem ]
then
    echo "${SCRIPT_NAME}: file ${prefix}private.pem already exist"
    exit 1
fi
#
if [ -f ${prefix}private_nopassphrase.pem ]
then
    echo "${SCRIPT_NAME}: file ${prefix}private_nopassphrase.pem already exist"
    exit 1
fi
#
if [ -f ${prefix}public*.pem ]
then
    echo "${SCRIPT_NAME}: file ${prefix}public.pem already exist"
    exit 1
fi
#
###############################################################################
#
echo "${SCRIPT_NAME}: extract certificate to file ${prefix}cert.pem"
${OPENSSL} ${pkcs12} -clcerts -nokeys -in ${keystoreP12} -passin pass:${passphrase} | sed -ne '/-----BEGIN /,/-----END /p' >${prefix}cert.pem || exit 1
chmod 644 ${prefix}cert.pem || exit 1
#
###############################################################################
#
echo "${SCRIPT_NAME}: extract certificate chain to file ${prefix}chain.pem"
${OPENSSL} ${pkcs12} -cacerts -nokeys -chain -in ${keystoreP12} -passin pass:${passphrase} | sed -ne '/-----BEGIN /,/-----END /p' >${prefix}chain.pem || exit 1
chmod 644 ${prefix}chain.pem || exit 1
#
###############################################################################
#
echo "${SCRIPT_NAME}: extract encrypted private key to file ${prefix}private.pem"
${OPENSSL} ${pkcs12} -nocerts -in ${keystoreP12} -passin pass:${passphrase} -passout pass:${passphrase} | sed -ne '/-----BEGIN /,/-----END /p' >${prefix}private.pem
chmod 600 ${prefix}private.pem || exit 1
#
###############################################################################
#
if [ ${nopassphrase} -eq 1 ]
then
    echo "${SCRIPT_NAME}: extract private key to file ${prefix}private_nopassphrase.pem"
    ${OPENSSL} ${pkcs12} -nocerts -in ${keystoreP12} -passin pass:${passphrase} -passout pass:${passphrase} | ${OPENSSL} rsa -passin pass:${passphrase} -passout pass:${passphrase} >${prefix}private_nopassphrase.pem
    chmod 600 ${prefix}private_nopassphrase.pem || exit 1
fi
#
###############################################################################
#
echo "${SCRIPT_NAME}: check private key part of file ${prefix}private.pem"
openssl pkey -check -noout -in ${prefix}private.pem -passin pass:${passphrase} || exit 1
#
echo "${SCRIPT_NAME}: check public key part of file ${prefix}private.pem"
openssl pkey -pubcheck -noout -in ${prefix}private.pem -passin pass:${passphrase} || exit 1
#
###############################################################################
#
echo "${SCRIPT_NAME}: extract public key to file ${prefix}public.pem"
${OPENSSL} pkey -in ${prefix}private.pem -passin pass:${passphrase} -pubout -out ${prefix}public.pem
chmod 644 ${prefix}public.pem || exit 1
#
###############################################################################
###############################################################################
#
type -p keytool >/dev/null 2>/dev/null
if [ $? -eq 0 ]
then
    rm -f ${keystoreJKS}
    echo "${SCRIPT_NAME}: create JKS keystore ${keystoreJKS}"
    keytool -importkeystore \
            -v \
            -srckeystore ${keystoreP12} \
            -destkeystore ${keystoreJKS} \
            -srcstoretype pkcs12 \
            -deststoretype jks \
            -srcstorepass ${passphrase} \
            -deststorepass ${passphrase}
    chmod 600 ${keystoreJKS} || exit 1
else
    echo "${SCRIPT_NAME}: can't create JKS keystore ${keystoreJKS}"
    echo "${SCRIPT_NAME}: (Java JDK keytool program not found in PATH)"
fi
#
###############################################################################
#
if [ ${legacy} -eq 1 ]
then
    rm -f ${keystoreP12_NL}
    echo "${SCRIPT_NAME}: create a none legacy version of the PKCS12 store"
    openssl pkcs12 -export \
        -in cert.pem \
        -inkey private.pem \
        -certfile chain.pem \
        -name 1  \
        -passin pass:${passphrase} \
        -passout pass:${passphrase} \
        -out ${keystoreP12_NL}
fi
#
###############################################################################
#
exit 0

