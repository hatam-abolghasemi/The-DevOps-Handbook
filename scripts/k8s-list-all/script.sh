#!/bin/bash

set -euo pipefail

read -rp "Enter Kubernetes namespace: " NAMESPACE

if ! kubectl get namespace "$NAMESPACE" >/dev/null 2>&1; then
  echo "❌ Namespace '$NAMESPACE' does not exist"
  exit 1
fi

echo "🔎 Scanning meaningful resources in namespace: $NAMESPACE"
echo

# ❌ Noise resources to skip
SKIP_REGEX="^(events|events\.events\.k8s\.io|endpoints|endpointslice|serviceaccounts|configmaps)$"

# Get all namespaced resource types
kubectl api-resources --verbs=list --namespaced -o name | while read -r res; do

  # Skip noisy resources
  if [[ "$res" =~ $SKIP_REGEX ]]; then
    continue
  fi

  output=$(kubectl get "$res" -n "$NAMESPACE" -o wide --ignore-not-found 2>/dev/null)

  if [[ -n "$output" ]]; then
    echo "===== RESOURCE: $res ====="
    echo "$output"
    echo
  fi

done

echo "🔎 Checking CRDs (operators / custom resources)..."
echo

# CRDs scoped to namespace (this is where operators live)
kubectl api-resources --namespaced=true -o name \
| while read -r crd; do

  output=$(kubectl get "$crd" -n "$NAMESPACE" --ignore-not-found 2>/dev/null)

  if [[ -n "$output" ]]; then
    echo "===== CRD: $crd ====="
    echo "$output"
    echo
  fi

done

echo "✅ Done."
