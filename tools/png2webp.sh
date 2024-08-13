PNGS=$(ls -rtl | grep png | awk -F " " '{print $9}')

for PNG in PNGS
do
	NAME=$(echo $PNG | awk -F "." '{print $9}')
	cwebp -q 80 $PNG -o $NAME.webp
done

