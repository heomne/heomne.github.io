#!/bin/bash
set -e

WORKING_DIR="/home/runner/work/heomne.github.io/heomne.github.io"
DIR_NAME=$(ls -1t ${WORKING_DIR}/_posts/ | head -n 1 | awk -F "-" '{print substr($0, index($0, $4))}' | sed 's/-$//')
DIR_PATH="${WORKING_DIR}/assets/post_img/"
FILE_NAME=$(ls -1t ${WORKING_DIR}/_posts/ | head -n 1)

printf "# Checking last posted file name: ${DIR_NAME}\n"

if [ -z "${DIR_NAME}" ] || [ ! -d "${DIR_PATH}${DIR_NAME}" ]; then
    echo "[INFO] no valid path provided"
    exit 0
fi

echo "DIR_PATH: ${DIR_PATH}${DIR_NAME}"

printf "# Convert PNG to WEBP: \n"

PNGS=$(find ${DIR_PATH}${DIR_NAME} -type f -name "*.png" -exec basename {} .png \;)

if [ -z "${PNGS}" ]; then
    printf "[INFO] No PNG files found. Exiting.\n"
    exit 0
else
    for PNG in $PNGS; do
        cwebp -q 80 "${DIR_PATH}${DIR_NAME}/${PNG}.png" -o "${DIR_PATH}${DIR_NAME}/${PNG}.webp"
        printf "Converted ${DIR_PATH}${DIR_NAME}/${PNG}.png to ${DIR_PATH}${DIR_NAME}/${PNG}.webp\n"
    done
fi

printf "# Changing markdown keyword(.png to .webp):"

if [ -f "${WORKING_DIR}/_posts/${FILE_NAME}" ]; then
    sed -i 's/.png/.webp/g' ${WORKING_DIR}/_posts/${FILE_NAME}
else
    printf "[INFO] Can't find markdown file. exiting...."
    exit 0
fi
