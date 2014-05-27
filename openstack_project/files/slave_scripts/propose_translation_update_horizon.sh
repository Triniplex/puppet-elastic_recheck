#!/bin/bash -xe

# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

ORG=openstack
PROJECT=horizon
COMMIT_MSG="Imported Translations from Transifex"

source /usr/local/jenkins/slave_scripts/common_translation_update.sh

setup_git

setup_review "$ORG" "$PROJECT"
setup_translation

# Horizon JavaScript Translations
tx set --auto-local -r ${PROJECT}.${PROJECT}-js-translations \
"${PROJECT}/locale/<lang>/LC_MESSAGES/djangojs.po" --source-lang en \
--source-file ${PROJECT}/locale/en/LC_MESSAGES/djangojs.po -t PO --execute
# Horizon Translations
tx set --auto-local -r ${PROJECT}.${PROJECT}-translations \
"${PROJECT}/locale/<lang>/LC_MESSAGES/django.po" --source-lang en \
--source-file ${PROJECT}/locale/en/LC_MESSAGES/django.po -t PO --execute
# OpenStack Dashboard Translations
tx set --auto-local -r ${PROJECT}.openstack-dashboard-translations \
"openstack_dashboard/locale/<lang>/LC_MESSAGES/django.po" --source-lang en \
--source-file openstack_dashboard/locale/en/LC_MESSAGES/django.po -t PO --execute

# Pull upstream translations of files that are at least 75 %
# translated
tx pull -a -f --minimum-perc=75

# Invoke run_tests.sh to update the po files
# Or else, "../manage.py makemessages" can be used.
./run_tests.sh --makemessages -V

# Add all changed files to git
git add horizon/locale/* openstack_dashboard/locale/*

# Don't send files where the only things which have changed are the
# creation date, the version number, the revision date, or comment
# lines.
for f in `git diff --cached --name-only`
do
  if [ `git diff --cached $f |egrep -v "(POT-Creation-Date|Project-Id-Version|PO-Revision-Date|^\+{3}|^\-{3}|^[-+]#)" | egrep -c "^[\-\+]"` -eq 0 ]
  then
      git reset -q $f
      git checkout -- $f
  fi
done

send_patch