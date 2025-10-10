#!/bin/bash

# Exit immediately if a command fails
set -eo pipefail

# --- Configuration ---
# You can override these by passing them as arguments to the script
# Usage: ./bundle-blueprints.sh <SECRET_NAME> <NAMESPACE>
SECRET_NAME="${1:-authentik-all-blueprints}"
NAMESPACE="${2:-authentik}"
SEARCH_DIR="homelab/apps"
OUTPUT_FILE="${SEARCH_DIR}/authentik/all_blueprints-secret.yaml"
SEALED_OUTPUT_FILE="${OUTPUT_FILE%-secret.yaml}.yaml"
# --- End of Configuration ---

# Ensure the output directory exists
mkdir -p "$(dirname "${OUTPUT_FILE}")"

# Find all blueprint files, excluding the output file itself from the search
mapfile -t blueprint_files < <(find "${SEARCH_DIR}" -type f \( -name "blueprint-secret.yaml" -o -name "blueprint-secret.yml" \) -not -path "${OUTPUT_FILE}" -not -path "${SEALED_OUTPUT_FILE}")

if [ ${#blueprint_files[@]} -eq 0 ]; then
    echo "No blueprint files found. Exiting."
    exit 0
fi

# Use a temporary file to build the manifest safely
TMP_FILE=$(mktemp)

# Write the static YAML header for a Secret to the temporary file
cat > "$TMP_FILE" <<EOF
apiVersion: v1
kind: Secret
metadata:
  name: ${SECRET_NAME}
  namespace: ${NAMESPACE}
data:
EOF

# Loop through each found file
for file in "${blueprint_files[@]}"; do
    # Create a unique key from the file path, e.g., "homelab/apps/app1/blueprint-secret.yaml" -> "homelab-apps-app1-blueprint-secret.yaml"
    key=$(echo "${file}" | sed 's/\//-/g')

    # Read the content, base64 encode it, and append to the temp file
    # The '-w 0' flag for base64 prevents line wrapping
    encoded_content=$(base64 -w 0 < "${file}")

    # Append the key and the base64 encoded value
    echo "  ${key}: ${encoded_content}" >> "$TMP_FILE"
done

# Atomically replace the old file with the new one
mv "$TMP_FILE" "$OUTPUT_FILE"

echo "Unsealed Secret manifest created at: ${OUTPUT_FILE}"

# Seal the generated Secret manifest
kubeseal --cert pub-sealed-secrets.pem < "$OUTPUT_FILE" --format yaml > "${SEALED_OUTPUT_FILE}"

echo "Sealed Secret successfully created at: ${SEALED_OUTPUT_FILE}"