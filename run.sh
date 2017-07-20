#!/bin/sh

set -eu

if [ -n "${OAP_DEBUG:-}" ] ; then
    set -x
fi

#set the max memory
BYTES_PER_MEG="$((1024 * 1024))"
BYTES_PER_GIG="$((1024 * BYTES_PER_MEG))"

DEFAULT_MIN="$((64 * BYTES_PER_MEG))" #This is a guess

if echo "${OCP_AUTH_PROXY_MEMORY_LIMIT:-}" | grep -qE "^([[:digit:]]+)([GgMm])?i?$"; then
    num="$(echo "${OCP_AUTH_PROXY_MEMORY_LIMIT}" | grep -oE "^[[:digit:]]+")"
    unit="$(echo "${OCP_AUTH_PROXY_MEMORY_LIMIT}" | grep -oE "[GgMm]" || echo "")"
    
    #set max_old_space_size to half of memory limit to allow some heap for other V8 spaces
    num=$((num/2))

    if [ "${unit}" = "G" ] || [ "${unit}" = "g" ]; then
        num="$((num * BYTES_PER_GIG))" # enables math to work out for odd Gi
    elif [ "${unit}" = "M" ]  || [ "${unit}" = "m" ]; then
        num="$((num * BYTES_PER_MEG))" # enables math to work out for odd Gi
    #else assume bytes
    fi

    if [ ${num} -lt ${DEFAULT_MIN} ] ; then
        echo "${num} is less than the default $((DEFAULT_MIN / BYTES_PER_MEG))m.  Setting to default."
        num="${DEFAULT_MIN}"
    fi

    export NODE_OPTIONS="${NODE_OPTIONS:---max_old_space_size=$((num / BYTES_PER_MEG))}"
else
    echo "Unable to process the OCP_AUTH_PROXY_MEMORY_LIMIT: '${OCP_AUTH_PROXY_MEMORY_LIMIT}'."
    echo "It must be a number, optionally followed by 'G'(Gigabytes) or 'M' (Megabytes), e.g. 64M"
    exit 1
fi

cd "${APP_DIR}"
echo "Using NODE_OPTIONS: '${NODE_OPTIONS}' Memory setting is in MB"
echo "Running from directory: '$(pwd)'"

scl enable rh-nodejs4 "node ${NODE_OPTIONS} openshift-auth-proxy.js"
