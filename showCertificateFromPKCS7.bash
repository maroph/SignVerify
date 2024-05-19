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
export LANG="en_US.UTF-8"
#
###############################################################################
#
print_usage() {
    cat <<EOT

Usage: ${SCRIPT_NAME} [<options>] <p7m/p7s file name>
       Show certificate used in a P7M/P7S file

    Options:
    -h|--help    : show this help text and exit
    -V|--version : show version information and exit

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
    echo "${SCRIPT_NAME}: P7M/P7S file name missing"
    exit 1
fi
pkcs7File=$1
#
if [ ! -r ${pkcs7File} ]
then
    echo "${SCRIPT_NAME}: can't read ${pkcs7File}"
    exit 1
fi
#
###############################################################################
#
openssl pkcs7 -inform der -in ${pkcs7File} -print_certs | openssl x509 -text
exit $?

