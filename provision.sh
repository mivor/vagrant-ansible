#! /bin/bash

RED="\033[31m"
GREEN="\033[32m"
NORMAL="\033[0m"

get_machine_name() {
    MACHINE_NAME=$(cat /etc/hostname)
}
set_ps() {
    sed -i -e 's/#force_color_prompt=/force_color_prompt=/g' /home/vagrant/.bashrc
    sed -i -e 's/\[\\033\[01;32m\\]\\u@\\h\\\[\\033\[00m\\]:\\\[\\033\[01;34m\\]/\[\\033\[36m\\]\\u\\\[\\033\[00m\\]@\\[\\033\[36m\\]\\h\\\[\\033\[00m\\]:\\\[\\033\[33m\\]/g' /home/vagrant/.bashrc
}

fix_tty() {
    sed -i -e 's/^mesg n/tty -s \&\& mesg n/g' /root/.profile
}

install_ansible() {
    apt-get update -qq
    apt-get install -qqy python-software-properties
    add-apt-repository ppa:rquillo/ansible
    apt-get update -qq
    apt-get install -qqy ansible
}

provision_ansible() {
    ANSIBLE_FORCE_COLOR="1" ansible-playbook -i /vagrant/provision/hosts /vagrant/provision/main.yml
}

set_insecure_ssh_key() { #ip addr
    GUEST_IP="$1"
    echo "IP: $GUEST_IP"
    su vagrant -c "wget -q -O /home/vagrant/.ssh/id_rsa https://raw.github.com/mitchellh/vagrant/master/keys/vagrant"
    chmod 600 /home/vagrant/.ssh/id_rsa
    su vagrant -c "ssh-keyscan -H $GUEST_IP > /home/vagrant/.ssh/known_hosts 2>/dev/null"
    GUEST_NAME=$(su vagrant -c "ssh $GUEST_IP 'cat /etc/hostname'")
    echo "NAME: $GUEST_NAME"
    su vagrant -c "echo \"Host $GUEST_NAME
    User vagrant
    HostName $GUEST_IP
    IdentityFile ~/.ssh/id_rsa\" > /home/vagrant/.ssh/config"
}

### Helpers

logger() { # ?m MSG func params
    # check if we expect output from command
    if [[ "$1" == "m" ]]; then
        IS_MULTI_LINE="true"
        shift
    fi
    # assign message to be printed
    local MSG="[$MACHINE_NAME] $1... "
    shift
    # print newline if multi line command
    if [[ "$IS_MULTI_LINE" == "" ]]; then
        printf "$MSG"
    else
        printf "$MSG\n"
    fi
    # execute command with leftover args
    "$@"
    # check comands error STATUS
    if [[ "$?" == 0 ]]; then
        STATUS=$GREEN"DONE"$NORMAL
    else
        STATUS=$RED"ERROR"$NORMAL
    fi
    # display error STATUS
    if [[ "$IS_MULTI_LINE" == "" ]]; then
        printf "$STATUS\n"
    else
        printf "$MSG$STATUS\n"
    fi
}

list_finished() { # list_name
    printf "===================\n"
    printf "$1 Finished!\n"
    printf "===================\n"
}

main() {
    get_machine_name
    if [[ $(type ansible 2>/dev/null) ]]; then
        logger 'm' "Running provisioner: ansible" provision_ansible
    else
        logger 'm' "Installing ansible" install_ansible
    fi
    # logger "Setting PS" set_ps
    # logger "Fixing tty bug" fix_tty
    # logger "m" "Setting up ssh" set_insecure_ssh_key $1

    # list_finished "Bootstraping Ansible"
}

main $@
