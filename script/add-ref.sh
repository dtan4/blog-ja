#!/bin/bash

set -eu
set -o pipefail

base_url="https://dtan4.hatenablog.com"

for file in $(find content/posts -type f -name '*-hatenablog.md'); do
  path="/entry/$(basename "${file}" | perl -pe "s|content/posts/||g;" -pe "s|-hatenablog\.md$||g;" -pe "s|-|/|g" )"
  url="${base_url}${path}"

  echo "" >> "${file}"
  echo "*(This post was imported from ${url})*" >> "${file}"
done
