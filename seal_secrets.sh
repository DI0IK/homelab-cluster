#!/bin/bash

# Exit immediately if a command fails or a variable is unset.
set -euo pipefail

# --- Configuration ---
# The directory to search for secret files.
SEARCH_DIR="."
# The public certificate for sealing secrets.
CERT_FILE="pub-sealed-secrets.pem"
# --- End of Configuration ---

# --- Main Script ---

# Check if the sealing certificate exists before proceeding.
if [ ! -f "$CERT_FILE" ]; then
    echo "Error: Sealing certificate '${CERT_FILE}' not found."
    echo "Please ensure the certificate is in the current directory or update the CERT_FILE variable."
    exit 1
fi

# Find all files ending in '-secret.ya?ml', excluding any named 'blueprint-secret.ya?ml'.
# The results are stored in the 'secret_files' array.
mapfile -t secret_files < <(find "${SEARCH_DIR}" -type f \( -name "*-secret.yaml" -o -name "*-secret.yml" \) -not -name "blueprint-secret.yaml" -not -name "blueprint-secret.yml")

# If no files are found, print a message and exit cleanly.
if [ ${#secret_files[@]} -eq 0 ]; then
    echo "No unsealed secret files found to process. Exiting."
    exit 0
fi

echo "Found ${#secret_files[@]} secret file(s) to seal."
echo "---"

# Loop through each found secret file.
for file in "${secret_files[@]}"; do
    # skip files containing 'disabled' in their name
    if [[ "$file" == *"disabled"* ]]; then
        echo "Skipping disabled file: ${file}"
        continue
    fi

    # Construct the output filename by removing the '-secret' suffix.
    # For example, 'app/credentials-secret.yaml' becomes 'app/credentials.yaml'.
    output_file="${file/-secret/}"

    echo "Processing: ${file}"

    # Run kubeseal on the file and write the output to the new filename.
    kubeseal --cert "${CERT_FILE}" < "${file}" --format yaml > "${output_file}"

    echo "  -> Sealed to: ${output_file}"
done

echo "---"
echo "All secret files have been sealed successfully."
