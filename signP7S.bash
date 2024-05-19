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
print_usage() {
    cat <<EOT

Usage: ${SCRIPT_NAME} [<options>] <file name>
       Create a P7S signature for a given file

    Options:
    -h|--help        : show this help text and exit
    -V|--version     : show version information and exit
    -f|--force       : TODO
    --cert <cert>    : certificate file
    --key <key>      : private key file
    --keypass <pass> : private key file
    --keydata <dir>  : TODO

    Arguments:
    file name : file to create a P7S (detached) signature
                the output adds the extension .p7s to the file name

EOT
}
#
###############################################################################
#
force=0
key=""
cert=""
keypass=""
keydata=""
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
        --key)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : key file name missing"
                exit 1
            fi
            key=$1
#
            if [ ! -r ${key} ]
            then
                echo "${SCRIPT_NAME}: can't read key file ${key}"
                exit 1
            fi
            ;;
        --keypass)
            shift
            if [ "$1" = "" ]
            then
                echo "${SCRIPT_NAME}: option ${option} : private key passphrase missing"
                exit 1
            fi
            keypass=$1
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
#
###############################################################################
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
###############################################################################
#
if [ "${keydata}" != "" ]
then
    if [ "${keypass}" = "" ]
    then
        if [ -r ${keydata}/private_nopassphrase.pem ]
        then
            if [ "${key}" = "" ]
            then
                key="${keydata}/private_nopassphrase.pem"
            fi
        fi
    fi
#
    if [ -r ${keydata}/private.pem ]
    then
        if [ "${key}" = "" ]
        then
            key="${keydata}/private.pem"
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
if [ "${key}" = "" ]
then
    echo "${SCRIPT_NAME}: key file name missing"
    exit 1
fi
#
if [ "${cert}" = "" ]
then
    echo "${SCRIPT_NAME}: cert file name missing"
    exit 1
fi
#
###############################################################################
#
if [ ${force} -eq 1 ]
then
    rm -f ${file}.p7s
fi
#
if [ -r ${file}.p7s ]
then
    echo "${SCRIPT_NAME}: ${file}.p7s already exist"
    exit 1
fi
#
###############################################################################
#
if [ "${keypass}" != "" ]
then
    openssl cms -sign -cades -binary -signer ${cert} -inkey ${key} -passin pass:${keypass} -in ${file} -md sha512 -outform der -out ${file}.p7s
    exit $?
else
    openssl cms -sign -cades -binary -signer ${cert} -inkey ${key} -in ${file} -md sha512 -outform der -out ${file}.p7s
    exit $?
fi

