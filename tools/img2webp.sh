#!/bin/bash

DIR_NAME=$(ls -l ../_posts/ | tail -n 1 | awk -F " " '{print $9}' | awk -F "-" '{for(i=4; i<=NF; i++) printf $i"-"}')
DIR_NAME=$(echo "${DIR_NAME::-4}")
DIR_PATH="/assets/post_img/"
FILE_NAME=$(ls -l ../_posts/ | awk -F " " '{print $9}' | tail -n 1)

printf "# Checking last posted file name: ${DIR_NAME}\n"

if [ -d "${DIR_PATH}${DIR_NAME}" ]; then 

	echo "DIR_PATH: "${DIR_PATH}${DIR_NAME}
	
else

	echo "[INFO] no path provided"
	exit 0

fi

printf "# Convert PNG to WEB: \n"

PNGS_CNT=$(ls -rtl ${DIR_PATH}${DIR_NAME} | grep .png | wc -l)

if [ "$PNGS_CNT" -eq 0 ]; then

	printf "[INFO] No PNG files found. Exiting.\n"
	exit 0

else 

	PNGS=$(ls -rtl ${DIR_PATH}${DIR_NAME} | grep .png | awk -F " " '{print $9}' | awk -F "." '{print $1}')

	for PNG in $PNGS
	do
		cwebp -q 80 "${DIR_PATH}${DIR_NAME}/${PNG}.png" -o "${DIR_PATH}${DIR_NAME}/${PNG}.webp"
		printf "Converted ${DIR_PATH}${DIR_NAME}/${PNG}.png to ${DIR_PATH}${DIR_NAME}/${PNG}.web\n"
	done

fi

printf "# Changing markdown keyword(.png to .webp):"

if [ -f "../_posts/${FILE_NAME}" ]; then

	sed -i 's/.png/.webp/g' ../_posts/${FILE_NAME}

else

	printf "[INFO] Can't found markdown file. exiting...."
	exit 0

fi
