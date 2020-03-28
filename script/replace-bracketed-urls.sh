#!/bin/bash

set -eu
set -o pipefail

base_url="http://cdn-ak.f.st-hatena.com/images/fotolife/d/dtan4"

for file in $(find content/posts -type f -name '*-hatenablog.md'); do
  perl -i -pe 's|^\[(https?://.+)\]$|\1|g' "${file}"
done
