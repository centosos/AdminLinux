#!/bin/bash

### USER SETUP ###
useradd --create-home --shell /bin/bash --password Qwerty123= foo
useradd --create-home --shell /bin/bash --password Qwerty123= bar
useradd --create-home --shell /bin/bash --password Qwerty123= buz

groupadd admin

usermod -aG admin foo
usermod -aG admin bar
usermod -aG admin root

### SSH SETUP ###
apt-get update -y
apt-get install -y ssh
systemctl enable --now sshd

### PAM SETUP ###
tee /etc/pam.d/sshd <<EOF
#%PAM-1.0
auth      required  pam_exec.so          /usr/lib/security/admin-weekends.sh
auth      include   system-remote-login
account   include   system-remote-login
password  include   system-remote-login
session   include   system-remote-login
EOF

tee /usr/lib/security/admin-weekends.sh <<EOF
#!/bin/bash

set -u -e

if groups $PAM_USER | grep -qv admin; then
  if (( `date +%u` >= 6 )); then
    exit 1
  fi
fi

set +u +e

exit 0
EOF

### INSTALL DOCKER ###
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt-get update -y
apt-cache policy docker-ce
apt-get install -y docker-ce

### GRANT PERMISSIONS FOR DOCKER ###
usermod -aG docker foo
usermod -aG docker "$USER"

tee /etc/sudoers.d/docker <<EOF
%docker ALL=(root) /usr/bin/systemctl reload docker, /usr/bin/systemctl restart docker
EOF

systemctl restart docker
