# Livebox to OVH DynHost

Updates (if required) the DynHost at OVH
Uses Livebox rest api to query for public IP

Mainly inspired by DynHost script given by OVH
This script uses 
- curl to get the public IP, and 
- wget to push new IP

## Config :
Uses a file (if it exists) with same name but extension .conf
Or direct environment variables

### Required
- DYNHOST  : DynHost name on OVH
- LOGIN    : DynHost credential 
- PASSWORD : DynHost credential 

### Optionals
- LOG_PATH : directory path to store logs (default /tmp)
- LIVEBOX  : the host name of the livebox seen by the macine running the script (default: livebox)

## Instalation of Systemd service + timer

This repo provides SystemD tools to run the update automatically
Just run as root the install script
`sudo ./install.sh`