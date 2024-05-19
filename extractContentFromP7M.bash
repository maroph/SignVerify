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

Usage: ${SCRIPT_NAME} [<options>]  <p7m file name>
       Extract the content from a P7M container

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
    echo "${SCRIPT_NAME}: file name missing"
    exit 1
fi
p7mFile=$1
#
if [ ! -r ${p7mFile} ]
then
    echo "${SCRIPT_NAME}: can't read ${p7mFile}"
    exit 1
fi
#
###############################################################################
#
openssl smime -verify -noverify -in ${p7mFile} -inform der
exit $?

