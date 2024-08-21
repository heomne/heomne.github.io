DIR_NAME=$(ls -rtl ../_posts/ | tail -n 1 | awk -F " " '{print $9}' | awk -F "-" '{for(i=4; i<=NF; i++) printf $i"-"}')
DIR_NAME=$(echo "${DIR_NAME::-4}")

DIR_PATH="../assets/post_img/${DIR_NAME}"


if [ -z "${DIR_PATH}" ]; then 

	echo "Error: no path provided"
	exit 1
	
else

	echo "DIR_PATH: "$DIR_PATH

fi


PNGS_CNT=$(ls -rtl $DIR_PATH | grep .png | wc -l)

if [ "$PNGS_CNT" -eq 0 ]; then

	echo "No PNG files found. Exiting."
	exit 0

else 

	PNGS=$(ls -rtl $DIR_PATH | grep .png | awk -F " " '{print $9}' | awk -F "." '{print $1}')

	for PNG in $PNGS
	do
		cwebp -q 80 "${DIR_PATH}/${PNG}.png" -o "${DIR_PATH}/${PNG}.webp"
	done
fi

