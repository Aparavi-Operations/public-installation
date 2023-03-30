# Aparavi Public Installation scripts

Aparavi repository that stores all of the code used for infrastructure provisioning on a customer side
Contains Ansible roles for configuring and deploying Aparavi app on baremetal hosts.

## Usage Example for Linux script

`curl -s https://raw.githubusercontent.com/Aparavi-Operations/public-installation/main/install.sh | sudo bash -s -- -n "appliance" -c "client_name" -o "parent_object_id"`

Required options:
* `-n` Node profile for deploying. Default: "basic"  
  * `appliance`  - MySQL server + Aparavi Appliance
  * `platform`   - MySQL server + Redis Server + Aparavi Platform

* `-c` Client name, assumed one deployment per client, in case of several deployments, just specify this like `new_client1_deployment1`, `new_client1_deployment2`, ..., `new_client1_deploymentN` per each deployment
* `-o` Parent object id provided by Aparavi. Example: "ddd-ddd-ddd-ddd"

* if `-n platform` you should provide:
    -p Aparavi platform address. Default "test.paas.aparavi.com"
    -g github user to clone private ansible-galaxy modules.
    -t github tocken to clone private ansible-galaxy modules

Additional options:
* `-a` Actual Aparavi platform URL to connect your AppAgent to. Default "preview.aparavi.com"
* `-p` DNS Name of the installed Platform, if you select `-n` profile as `platform`. Default "test.paas.aparavi.com"
* `-l` Actual Aparavi log collector URL. Default: "logstash.aparavi.com"
* `-m` Mysql AppUser name. Default: "aparavi_app"
* `-d` Install TMP dir. Default: "/tmp/debian11-install"
* `-v` Verbose on or off. Default: "on"
* `-b` Git branch to clone. Default: "main"
* `-u` URL to download AppAgent. Default: "https://aparavi.jfrog.io/artifactory/aparavi-installers-public/linux-installer-latest.run"

## Example
`install.sh -n "full" -c "client_name" -o "parent_object_id`

## Directory Structure

Shell script - the only file you need to run for Linux
* [`install.sh`](install.sh)   
Shell script - the only file you need to run for Windows
* [`install.ps1`](install.sh)   
Ansible roles used to deploy projects:
* [`ansible/roles/`](ansible/roles/)   

### More usage examples   

Platform installation:    
* `curl -s https://raw.githubusercontent.com/Aparavi-Operations/public-installation/main/install.sh | bash -s -- -n "platform" -c "client_name" -p "test.paas.aparavi.com" -g github_user -t github_token` 

## Usage Example for Windows PowerShell Script

To install aggregator-collector on a Windows host, follow these steps:

1. Open Windows Terminal as an administrator.   
2. Copy and paste the following code:   

```powershell
$tempFolder = New-Item -ItemType Directory -Path $env:TEMP\MyTempFolder
$url = 'https://raw.githubusercontent.com/Aparavi-Operations/public-installation/main/install.ps1'
Invoke-WebRequest $url -OutFile "$tempFolder\install.ps1"
cd $tempFolder
& .\install.ps1 -a "preview.aparavi.com" -o "aaa-bbbb-cccc-dddd-eeee"
```
3. replace `preview.aparavi.com` with the URL of the Aparavi platform you want to connect to.
4. Replace `aaa-bbbb-cccc-dddd-eeee` with the parentId of the object you want to connect the application to.

### Parameters

The PowerShell script accepts the following parameters:

* `-n` profile: The deploy profile to apply. The options are `aggregator-collector`, `aggregator`, `collector`, `platform`, `worker`, `db`, or `monitoring-only`. The default value is `aggregator-collector`.
* `-o` parentId: The parentId of the object to connect this application to. This parameter is mandatory.
* `-a` bindAddress: The platform endpoint. The default value is `preview.aparavi.com`.
* `-l` logstashAddress: The Logstash connecting endpoint. The default value is `logstash-ext.paas.aparavi.com:5044`.
* `-b` gitBranch: The automation branch name. The default value is `main`.
* `-u` downloadUrl: The application installer URL. The default value is `https://aparavi.jfrog.io/artifactory/aparavi-installers-public/windows-installer-latest.exe`.
* `-m` mysqlUser: The application database username. The default value is `aparavi_app`.
