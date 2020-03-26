#!/bin/bash

set -eu
set -o pipefail

HATENABLOG_USER="dtan4"
HATENABLOG_DOMAIN="dtan4.hatenablog.com"
HATENABLOG_ENTRIES_DIR="entry"
HUGO_ENTRIES_DIR="entry-new"

hatenablog_domain_regexp="$(echo -n ${HATENABLOG_DOMAIN} | perl -pe "s/\./\\\\./g")"

for post in $(find "${HATENABLOG_ENTRIES_DIR}" -type f -name "*.md"); do
  if grep -q "Draft: true" "${post}"; then
    echo "[INFO] skip draft post ${post}"
    continue
  fi

  echo "[INFO] convert ${post}"

  new_post="$(echo -n ${post#"${HATENABLOG_ENTRIES_DIR}/"} | perl -pe 's|/|-|g;' -pe 's|\.md|-hatenablog.md|g;')"

  perl -pe "s/Title: '(.+)'/title: \"\\1\"/g;" \
       -pe "s/Title: (.+)/title: \"\\1\"/g;" \
       -pe "s/Date: /date: /g;" \
       -pe "s|URL: https://${hatenablog_domain_regexp}/entry/\d+/\d+/\d+/\d+\n||g;" \
       -pe "s|EditURL: https://blog\.hatena\.ne\.jp/${HATENABLOG_USER}/${hatenablog_domain_regexp}/atom/entry/\d+|tags: [\"hatenablog\"]|g;" \
       "${post}" > "${HUGO_ENTRIES_DIR}/${new_post}"
done
