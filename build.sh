# get flags
while getopts 'f' flag; do
  case "${flag}" in
    f) NO_CACHE='true' ;;
  esac
done

# cleanup build
rm -rf build/*

# set theme
THEME="system"
echo "Building for $(tput setaf 4)$THEME$(tput sgr0) theme"

DARK_FOLDER="FolderDark512x512@2x.png"
LIGHT_FOLDER="Folder512x512@2x.png"

if [ $THEME == "system" ]; then
  if [ "$(defaults read -g AppleInterfaceStyle)" == "Dark" ]; then
    THEME_FOLDER_FILE=$DARK_FOLDER
  else
    THEME_FOLDER_FILE=$LIGHT_FOLDER
  fi
else
  if [ "$THEME" = "dark" ]; then
    THEME_FOLDER_FILE=$DARK_FOLDER
  else
    THEME_FOLDER_FILE=$LIGHT_FOLDER
  fi
fi

# extract blank folder from OS assets
ASSETS_LOCATION="/System/Library/PrivateFrameworks/IconFoundation.framework/Versions/A/Resources/Assets.car"
TEMP=$TMPDIR/io.kmr.folderIcons
FOLDER_ICON="$TEMP/$THEME_FOLDER_FILE"

if [[ $NO_CACHE ]]; then
  rm -rf $TEMP
fi

if test -f "$FOLDER_ICON"; then
  echo "$(tput setaf 3)Blank folder already extracted, skipping...$(tput sgr0)"
else
  echo "Extracting blank folder"
  ./bin/acextract -i $ASSETS_LOCATION -o $TEMP > /dev/null
fi

# convert svgs
echo "Converting custom icons"
mogrify -density 2000 -resize x512 -background transparent -format png -path custom/ custom/*.svg

# build custom icon folders
echo "Building custom icons"
for file in custom/*.png; do
  FILENAME=$(echo "$file" | cut -f 1 -d '.')
  BASENAME="$(BASENAME "$FILENAME")"

  convert $FOLDER_ICON \
    \( -background transparent -size 512x512 -gravity center -geometry +0+40 $file -resize X300 -colorize 100 -fill '#1ca1dd' +opaque "#00000000" \) \
    -compose over -composite "build/$BASENAME.png"
done

# build SF Pro icon folders
echo "Building symbol icons"
SYMBOLS=$(cat symbols.txt)

for ((i = 0; i < ${#SYMBOLS}; i++)); do
  SYMBOL="${SYMBOLS:$i:1}"
  convert $FOLDER_ICON \
    \( -background transparent -fill '#1ca1dd' -font SF-Pro-Text-Regular -size 512x512 -pointsize 340 -gravity center -geometry +0+40 label:$SYMBOL \) \
    -compose over -composite build/$SYMBOL.png
done

# build
echo "Building .icns files"
for file in build/*.png; do
  FILENAME=$(echo "$file" | cut -f 1 -d '.')
  mkdir "$FILENAME.iconset"

  sips -z 16 16 "$FILENAME.png" --out "$FILENAME.iconset/icon_16x16.png" > /dev/null
  sips -z 32 32 "$FILENAME.png" --out "$FILENAME.iconset/icon_16x16@2x.png" > /dev/null
  sips -z 32 32 "$FILENAME.png" --out "$FILENAME.iconset/icon_32x32.png" > /dev/null
  sips -z 64 64 "$FILENAME.png" --out "$FILENAME.iconset/icon_32x32@2x.png" > /dev/null
  sips -z 128 128 "$FILENAME.png" --out "$FILENAME.iconset/icon_128x128.png" > /dev/null
  sips -z 256 256 "$FILENAME.png" --out "$FILENAME.iconset/icon_128x128@2x.png" > /dev/null
  sips -z 256 256 "$FILENAME.png" --out "$FILENAME.iconset/icon_256x256.png" > /dev/null
  sips -z 512 512 "$FILENAME.png" --out "$FILENAME.iconset/icon_256x256@2x.png" > /dev/null
  sips -z 512 512 "$FILENAME.png" --out "$FILENAME.iconset/icon_512x512.png" > /dev/null
  cp "$FILENAME.png" "$FILENAME.iconset/icon_512x512@2x.png"

  iconutil -c icns "$FILENAME.iconset"
  rm -R "$FILENAME.iconset"
done

# cleanup build
rm -rf build/*.iconset build/*.png
echo "$(tput setaf 2)Build complete!$(tput sgr0) Icons are located in the $(tput setaf 4)build$(tput sgr0) folder."
