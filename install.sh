#! /bin/bash
# Install the required SytemD files

set -o errexit    # always exit on error
set -o pipefail   # honor exit codes when piping
set -o nounset  # fail on unset variables

currentdir=$(cd -P -- "$(dirname -- "$BASH_SOURCE[0]")" && pwd -P)

# Error message plus exit
# $* message
fail() {
  >&2 echo -e "$(logTimestamp) $@"
  exit 1
}

[ -d /etc/systemd/system/ ] ||  fail "SystemD not found"

echo "Configure Service "
sed "s|/opt/dynhost_ovh_livebox/|${currentdir}/|g" "${currentdir}/dynhost_ovh_livebox.service" > "/etc/systemd/system/dynhost_ovh_livebox.service"
echo "Configure Timer "
cp "${currentdir}/dynhost_ovh_livebox.timer" > "/etc/systemd/system/dynhost_ovh_livebox.timer"

echo "Start service & timer"
systemctl daemon-reload
systemctl enable dynhost_ovh_livebox.timer dynhost_ovh_livebox.service
systemctl start dynhost_ovh_livebox.timer

echo "Done"
echo "You can run it manually using "
echo "systemctl start dynhost_ovh_livebox.service"
