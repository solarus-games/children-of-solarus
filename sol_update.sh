#!/bin/sh

#Directory of the ZSDX game we are updating from
ZSDX_DIR="../zsdx"

#Copy all files from lua-containing directories
echo "Copying lua files."
cp ${ZSDX_DIR}/data/*.lua ./data/*.lua
cp ${ZSDX_DIR}/data/enemies/*.lua ./data/enemies/*.lua
cp ${ZSDX_DIR}/data/hud/*.lua ./data/hud/*.lua
cp ${ZSDX_DIR}/data/items/*.lua ./data/items/*.lua
cp ${ZSDX_DIR}/data/maps/*.lua ./data/maps/*.lua
cp ${ZSDX_DIR}/data/maps/lib/*.lua ./data/maps/lib/*.lua
cp ${ZSDX_DIR}/data/menus/*.lua ./data/menus/*.lua
echo "Copied all lua files."

#Rename names for files and text.
echo "Renaming files and text."

#Rename text
for file in *.lua; do
   sed -i 's/Agahnim/Lunarius/g' $file
   sed -i 's/Ganon/Neptune/g' $file
   sed -i 's/Zelda/Solaritine/g' $file
   sed -i 's/Rupee/Gem/g' $file
   sed -i 's/agahnim/lunarius/g' $file
   sed -i 's/ganon/neptune/g' $file
   sed -i 's/zelda/solaritine/g' $file
   sed -i 's/rupee/gem/g' $file
done
echo "Renamed text."

#Rename files
mv ./data/enemies/agahnim*.lua ./data/enemies/lunarius*.lua
mv ./data/enemies/ganon.lua ./data/enemies/neptune.lua
mv ./data/items/rupee*.lua ./data/items/gem*.lua
echo "Renamed files."
echo "Finished importing lua scripts."