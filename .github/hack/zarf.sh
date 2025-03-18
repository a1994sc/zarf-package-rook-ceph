#!/usr/bin/env bash

set -euo pipefail

for module in `ls */zarf.yaml`; do
  export IMAGES=`zarf dev find-images --skip-cosign $(dirname $module) 2>/dev/null | yq '(del(.components[].images[] | select(test("^127") or test("\*$"))) | .components[].images | select(. | length > 0)) // []'`
  yq -i '.components[0].images= ((.x-charts + env(IMAGES)) | ... comments="" | sort | unique)' $module
  yq -i '.components[1].images= ((.x-charts + env(IMAGES)) | ... comments="" | sort | unique)' $module
  unset IMAGES
done
