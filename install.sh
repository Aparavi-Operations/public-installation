#!/bin/bash

usage () {
    cat <<EOH

$0 -n "full" -c "client_name" -o "ddd-ddd-ddd-ddd" [additional_options]

Required options:
    -n Node profile for deploying. Default: "appliance"
       appliance    - MySQL server + Redis Server + Aparavi Appliance
       platform     - MySQL server + Redis Server + Aparavi Platform

       ############ lazy dba profile ############
       mysql_only  - basic profile + MySQL server

    -c Client name. Example "Aparavi"
    -o Aparavi parent object ID. Example: "ddd-ddd-ddd-ddd"
    -g github user to clone submodule with platform installation
    -t github tocken to clone submodule with platform installation

Additional options:
    -a Aparavi platform bind address. Default "preview.aparavi.com"
    -p Aparavi platform address. Default "test.paas.aparavi.com"
    -l Logstash address. Default: "logstash.aparavi.com"
    -m Mysql AppUser name. Default: "aparavi_app"

Nerds options:
    -d Install TMP dir. Default: "/tmp/debian11-install"
    -v Verbose on or off. Default: "on"
    -b Git branch to clone. Default: "main"
    -u Aparavi app download url. Default: "https://aparavi.jfrog.io/artifactory/aparavi-installers-public/linux-installer-latest.run"
EOH
}

while getopts ":a:c:o:p:l:m:d:v:b:n:u:g:t:" options; do
    case "${options}" in
        c)
            NODE_META_SERVICE_INSTANCE=${OPTARG}
            ;;
        o)
            APARAVI_PARENT_OBJECT_ID=${OPTARG}
            ;;
        a)
            APARAVI_PLATFORM_BIND_ADDR=${OPTARG}
            ;;
        p)
            APARAVI_PLATFORM_ADDR=${OPTARG}
            ;;
        l)
            LOGSTASH_ADDRESS=${OPTARG}
            ;;
        m)
            MYSQL_APPUSER_NAME=${OPTARG}
            ;;
        d)
            INSTALL_TMP_DIR=${OPTARG}
            ;;
        v)
            VERBOSE_ON_OFF=${OPTARG}
            ;;
        b)
            GIT_BRANCH=${OPTARG}
            ;;
        n)
            NODE_PROFILE=${OPTARG}
            ;;
        u)  
            DOWNLOAD_URL=${OPTARG}
            ;;
        g)
            GIT_USER=${OPTARG}
            ;;
        t)  
            GIT_PASSWORD=${OPTARG}
            ;;
        :)  # If expected argument omitted:
            echo "Error: -${OPTARG} requires an argument."
            usage
            exit 1
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

###### required switches checking ###### 
function check_c_switch {
if [[ -z "$NODE_META_SERVICE_INSTANCE" ]]; then
    echo "Error: Option '-c' is required for selected clinet name."
    usage
    exit 1
fi
}

function check_o_switch {
if [[ -z "$APARAVI_PARENT_OBJECT_ID" ]]; then
    echo "Error: Option '-o' is required for Aparavi parent object ID."
    usage
    exit 1
fi
}

function check_p_switch {
if [[ -z "$APARAVI_PLATFORM_ADDR" ]]; then
    echo "Error: Option '-p' is required for Aparavi platform address."
    usage
    exit 1
fi
}

function check_g_switch {
if [[ -z "$GIT_USER" ]]; then
    echo "Error: Option '-g' is required for github user."
    usage
    exit 1
fi
}

function check_t_switch {
if [[ -z "$GIT_PASSWORD" ]]; then
    echo "Error: Option '-t' is required for github token."
    usage
    exit 1
fi
}

function galaxy_portal {
    git config credential.helper '!f() { sleep 1; echo "username=${GIT_USER}"; echo "password=${GIT_PASSWORD}"; }; f'
    ansible-galaxy install -r roles/requirements-portal.yml
}

###### end of required switches checking ###### 
###### Node profile dictionary ######
[[ -z "$NODE_PROFILE" ]]&&NODE_PROFILE="appliance"

    case "${NODE_PROFILE}" in
        appliance)
            check_o_switch
            NODE_ANSIBLE_TAGS="-t mysql_server,aparavi_appagent"
            ;;
        platform)
            check_p_switch
            check_g_switch
            check_t_switch
            NODE_ANSIBLE_TAGS="-t mysql_server,redis_server,platform"
            ;;
        mysql_only)
            NODE_ANSIBLE_TAGS="-t mysql_server"
            ;;
        *)
        echo "Error: please provide node profile (\"-n\" switch) from the list: basic, secure, monitoring, appliance, platform, full, mysql_only"
            usage
            exit 1
            ;;
    esac
###### end of node profile dictionary ######

shift "$((OPTIND-1))"
if [[ $# -ge 1 ]]; then
    echo "Error: '$@' - non-option arguments. Don't use them"
    usage
    exit 1
fi

[[ "$VERBOSE_ON_OFF" == "off" ]]&&VERBOSE=""||VERBOSE="-vv"

[[ -z "$APARAVI_PLATFORM_BIND_ADDR" ]]&&APARAVI_PLATFORM_BIND_ADDR="preview.aparavi.com"

[[ -z "$APARAVI_PLATFORM_ADDR" ]]&&APARAVI_PLATFORM_ADDR="test.paas.aparavi.com"

[[ -z "$LOGSTASH_ADDRESS" ]]&&LOGSTASH_ADDRESS="logstash.aparavi.com"

[[ -z "$MYSQL_APPUSER_NAME" ]]&&MYSQL_APPUSER_NAME="aparavi_app"
[[ -z "$INSTALL_TMP_DIR" ]]&&INSTALL_TMP_DIR="/tmp/debian11-install"
[[ -z "$GIT_BRANCH" ]]&&GIT_BRANCH="main"
[[ -z "$DOWNLOAD_URL" ]]&&DOWNLOAD_URL_VAR=""||DOWNLOAD_URL_VAR="aparavi_app_url=$DOWNLOAD_URL"

########################
### for servers without sshd service
[[ -f "/etc/ssh/ssh_host_ecdsa_key" ]]||ssh-keygen -A
[[ -d "/run/sshd" ]]||mkdir -p /run/sshd

sed -i 's/deb cdrom/#deb cdrom/' /etc/apt/sources.list
apt update
apt install ansible git sshpass vim python3-mysqldb sudo gnupg2 -y

### Make sure target directory exists and empty
mkdir -p $INSTALL_TMP_DIR
cd $INSTALL_TMP_DIR
[ -d "./public-installation" ] && rm -rf ./public-installation

###### download all ansible stuff to the machine ######
git clone -b $GIT_BRANCH https://github.com/Aparavi-Operations/public-installation.git
cd public-installation/ansible/
export ANSIBLE_ROLES_PATH="$INSTALL_TMP_DIR/public-installation/ansible/roles/"
ansible-galaxy install -r roles/requirements.yml

#### Install additional roles
case "${NODE_PROFILE}" in
    platform)
        echo "galaxy_portal"
        galaxy_portal
        ;;
esac

###### run ansible ######
# ansible-playbook --connection=local $INSTALL_TMP_DIR/public-installation/ansible/playbooks/base/main.yml -i 127.0.0.1, $VERBOSE $NODE_ANSIBLE_TAGS \
#     --extra-vars    "mysql_appuser_name=$MYSQL_APPUSER_NAME \
#                     aparavi_platform_bind_addr=$APARAVI_PLATFORM_BIND_ADDR \
#                     aparavi_platform_addr=$APARAVI_PLATFORM_ADDR \
#                     node_meta_service_instance=$NODE_META_SERVICE_INSTANCE \
#                     aparavi_parent_object=$APARAVI_PARENT_OBJECT_ID \
#                     install_tmp_dir=$INSTALL_TMP_DIR \
#                     $DOWNLOAD_URL_VAR"
