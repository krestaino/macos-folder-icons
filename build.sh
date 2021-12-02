# cleanup build
rm -rf build/*

# set theme
theme="auto"
dark_folder="FolderDark512x512@2x.png"
light_folder="Folder512x512@2x.png"

if [ $theme == "auto" ]; then
  if [ "$(defaults read -g AppleInterfaceStyle)" == "Dark" ]; then
      theme_folder_file=$dark_folder
  else
      theme_folder_file=$light_folder
  fi
else
  if [ "$theme" = "dark" ]; then
      theme_folder_file=$dark_folder
  else
      theme_folder_file=$light_folder
  fi
fi

# extract blank folder from OS assets
assets_location="/System/Library/PrivateFrameworks/IconFoundation.framework/Versions/A/Resources/Assets.car"
temp=$TMPDIR/AssetsOutput

./bin/acextract -i $assets_location -o $temp
folder_icon="$temp/$theme_folder_file"

# convert svgs
mogrify -density 2000 -resize x512 -background transparent -format png -path custom/ custom/*.svg

# build custom icon folders
for file in custom/*.png; do
  filename=$(echo "$file" | cut -f 1 -d '.')
  basename="$(basename "$filename")"

  convert $folder_icon \
    \( -background transparent -size 512x512 -gravity center -geometry +0+40 $file -resize X300 -colorize 100 -fill '#1ca1dd' +opaque "#00000000" \) \
    -compose over -composite "build/$basename.png"
done

# build SF Pro icon folders
symbols=`cat symbols.txt`

for (( i=0; i<${#symbols}; i++ )); do
  symbol="${symbols:$i:1}"
  convert $folder_icon \
    \( -background transparent -fill '#1ca1dd' -font SF-Pro-Text-Regular -size 512x512 -pointsize 340 -gravity center -geometry +0+40 label:$symbol \) \
    -compose over -composite build/$symbol.png
done

# build 
for file in build/*.png; do
  filename=$(echo "$file" | cut -f 1 -d '.')
  mkdir "$filename.iconset"

  sips -z 16 16     "$filename.png" --out "$filename.iconset/icon_16x16.png"
  sips -z 32 32     "$filename.png" --out "$filename.iconset/icon_16x16@2x.png"
  sips -z 32 32     "$filename.png" --out "$filename.iconset/icon_32x32.png"
  sips -z 64 64     "$filename.png" --out "$filename.iconset/icon_32x32@2x.png"
  sips -z 128 128   "$filename.png" --out "$filename.iconset/icon_128x128.png"
  sips -z 256 256   "$filename.png" --out "$filename.iconset/icon_128x128@2x.png"
  sips -z 256 256   "$filename.png" --out "$filename.iconset/icon_256x256.png"
  sips -z 512 512   "$filename.png" --out "$filename.iconset/icon_256x256@2x.png"
  sips -z 512 512   "$filename.png" --out "$filename.iconset/icon_512x512.png"
  cp "$filename.png" "$filename.iconset/icon_512x512@2x.png"

  iconutil -c icns "$filename.iconset"
  rm -R "$filename.iconset"
done

# cleanup build
rm -rf build/*.iconset build/*.png
