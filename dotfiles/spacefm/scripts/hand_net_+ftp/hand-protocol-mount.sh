#!/bin/bash

options="allow_other,ro"
if [ -n "%user%" ]; then
    user=",user=%user%"
    [[ -n "%pass%" ]] && user="$user:%pass%"
fi
[[ -n "%port%" ]] && portcolon=:
echo ">>> curlftpfs -o $options$user ftp://%host%${portcolon}%port%%path% %a"
echo
curlftpfs -o $options$user ftp://%host%${portcolon}%port%%path% "%a"
[[ $? -eq 0 ]] && sleep 1 && ls "%a"  # set error status or wait until ready
