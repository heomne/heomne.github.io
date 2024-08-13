DIR_PATH=$(realpath "$1")
if [ -z "$1" ]; then 
	echo "Error: no path provided"
	exit 1
	
	else
	echo $DIR_PATH
fi

PNGS=$(ls -rtl $DIR_PATH | grep .png | awk -F " " '{print $9}' | awk -F "." '{print $1}')
echo $PNGS

for PNG in $PNGS
do
	cwebp -q 80 "${DIR_PATH}/${PNG}.png" -o "${DIR_PATH}/${PNG}.webp"
done

