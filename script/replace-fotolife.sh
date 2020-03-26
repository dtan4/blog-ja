#!/bin/bash

set -eu
set -o pipefail

base_url="http://cdn-ak.f.st-hatena.com/images/fotolife/d/dtan4"

for file in $(find content/posts -type f -name '*-hatenablog.md'); do
  for foto in $(grep -E "\[f:id\:dtan4\:(\d+)p:plain\]" "${file}"); do
    id="$(echo -n "${foto}" | perl -pe 's/\[f:id\:dtan4\:(\d+)p:plain\]/\1/g')"
    date="$(echo -n "${id}" | perl -pe 's/(\d{8})\d+/\1/g')"
    url="${base_url}/${date}/${id}.png"

    wget -O "static/images/${id}.png" "${url}"

    perl -i -pe "s|\\Q${foto}\\E|![](/images/${id}.png)|" "${file}"
  done
done
