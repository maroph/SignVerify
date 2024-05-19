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
declare -r SCRIPT_NAME=$(basename $0)
declare -r VERSION="${SCRIPT_NAME}  1  (19-MAY-2024)"
#
###############################################################################
#
umask 0027
export LANG="en_US.UTF-8"
#
###############################################################################
#
cert=""
chain=""
keydata=""
#
###############################################################################
#
print_usage() {
    cat <<EOT

Usage: ${SCRIPT_NAME} [<options>] <file name>
       Verify a P7S signature for a given file

    Options:
    -h|--help       : show this help text and exit
    -V|--version    : show version information and exit
    --cert <cert>   : certificate file
    --chain <chain> : certificate chain PEM file
    --keydata <dir> : TODO

    Arguments:
    file name : name of the file with the P7S (detached) signature
                the expected P7S file name is the given file name
                with the extension .p7s added to the file name
 

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
        --cert)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : cert file name missing"
                exit 1
            fi
            cert=$1
#
            if [ ! -r ${cert} ]
            then
                echo "${SCRIPT_NAME}: can't read cert file ${cert}"
                exit 1
            fi
            ;;
        --chain)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : chain file name missing"
                exit 1
            fi
            chain=$1
#
            if [ ! -r ${chain} ]
            then
                echo "${SCRIPT_NAME}: can't read cert file ${chain}"
                exit 1
            fi
            ;;
        --keydata)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : keydata directory name missing"
                exit 1
            fi
            keydata=$1
#
            if [ ! -d ${keydata} ]
            then
                echo "${SCRIPT_NAME}: not a directory: ${keydata}"
                exit 1
            fi
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
# ###############################################################################
#
if [ "$1" = "" ]
then
    echo "${SCRIPT_NAME}: file name missing"
    exit 1
fi
file=$1
#
if [ ! -r ${file} ]
then
    echo "${SCRIPT_NAME}: can't read ${file}"
    exit 1
fi
#
if [ ! -r ${file}.p7s ]
then
    echo "${SCRIPT_NAME}: can't read ${file}.p7s"
    exit 1
fi
#
###############################################################################
#
if [ "${keydata}" != "" ]
then
    if [ -r ${keydata}/chain.pem ]
    then
        if [ "${chain}" = "" ]
        then
            chain="${keydata}/chain.pem"
        fi
    fi
#
    if [ -r ${keydata}/cert.pem ]
    then
        if [ "${cert}" = "" ]
        then
            cert="${keydata}/cert.pem"
        fi
    fi
fi
#
###############################################################################
#
if [  "${chain}" = "" ]
then
    echo "${SCRIPT_NAME}: chain file name not set"
    exit 1
fi
#
if [ "${cert}" = "" ]
then
    echo "${SCRIPT_NAME}: cert file not set"
    exit 1
fi
#
###############################################################################
#
openssl cms -verify -cades -binary -in ${file}.p7s -inform der -content ${file} -CAfile ${chain} -certfile ${cert} >/dev/null || exit 1
#
###############################################################################
#
openssl pkcs7 -inform der -in ${file}.p7s -print_certs | openssl x509 -text -noout | head -10
exit $?

