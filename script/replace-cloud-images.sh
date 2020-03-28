#!/bin/bash

set -eu
set -o pipefail

for file in $(find content/posts -type f -name '*-hatenablog.md'); do
  while read -r image; do
    url=$(echo -n "${image}" | perl -pe 's|\s*(\* )?!\[.*\]\(||g;' -pe 's|\)$||g;')
    filename="$(basename "${url}")"

    set +e
    wget -O "static/images/${filename}" "${url}" || rm -f "static/images/${filename}" > /dev/null
    set -e

    perl -i -pe "s|\\Q${image}\\E|![](/images/${filename})|" "${file}"
  done < <(grep -E "!\[.*\]\(https?://.+)" "${file}" | grep -v badge | grep -v quay)
done
