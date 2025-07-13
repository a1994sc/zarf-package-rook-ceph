#!/usr/bin/env bash

set -euo pipefail

declare -a FLAVOR=("upstream")
declare -a COMPONENTS=("operator" "cluster")
declare -a COMPONENTS_TYPES=("" "-seed")

for flavor in "${FLAVOR[@]}"; do
  rm -rf .direnv/$flavor
  mkdir -p .direnv/$flavor
  zarf dev find-images --flavor $flavor --skip-cosign . 2>/dev/null > .direnv/$flavor/out.yml
  for component in "${COMPONENTS[@]}"; do
    for type in "${COMPONENTS_TYPES[@]}"; do
      export yq_search=$(printf '.components[] | select(.name == "%s%s" and .only.flavor == "%s") | path | .[1]' "$component" "$type" "$flavor")
      export yq_index=$(yq "$yq_search" zarf.yaml)
      export yq_images=$(printf '(select(fi == 1) | .components[] | select(.name == "%s") | .images | ... head_comment="") as $img' "$component")
      export yq_charts=$(printf '(select(fi == 0) | .x-charts.%s) as $cht' "$component")
      export yq_update=$(printf '(select(fi == 0) | .components[%s].images = ($img + $cht | sort))' "$yq_index")
      yq ea -i "$yq_images | $yq_charts | $yq_update" zarf.yaml .direnv/$flavor/out.yml
    done
  done
done
