cat << EOF >> ~/.ssh/config

Host ${username}
    HostName ${hostname}
    User ${user}
    IdentityFile ${identityfile}
EOF