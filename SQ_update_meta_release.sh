#!/bin/bash

cd /data/apache2-mirror/html

rm meta-{release,release-lts}

wget http://changelogs.ubuntu.com/meta-{release,release-lts}

cd /data/mirror/mirror

for meta in $(egrep -e "Release-File|ReleaseNotes|ReleaseNotesHtml|UpgradeTool|UpgradeToolSignature" /data/apache2-mirror/html/meta-{release,release-lts} |awk '{print $2}');do wget -x ${meta};done

rm -r /data/mirror/mirror/old-releases.ubuntu.com

chown -R apt-mirror:apt-mirror /data/mirror/mirror/archive.ubuntu.com/ubuntu

sed -i 's/archive.ubuntu.com/linuxmirror.info.swissquote.ch/g' /data/apache2-mirror/html/meta-{release,release-lts}
sed -i 's/changelogs.ubuntu.com/linuxmirror.info.swissquote.ch/g' /data/apache2-mirror/html/meta-{release,release-lts}