#!/bin/bash

#Rename names for files and text.
echo "Renaming text."

#Rename text
for file in data/*/*.lua; do
   sed -i 's/Agahnim/Lunarius/g' $file
   sed -i 's/Ganondorf/Neptune/g' $file
   sed -i 's/Ganon/Neptune/g' $file
   sed -i 's/Zelda/Solarina/g' $file
   sed -i 's/Rupee/Gem/g' $file
   sed -i 's/agahnim/lunarius/g' $file
   sed -i 's/ganondorf/neptune/g' $file
   sed -i 's/ganon/neptune/g' $file
   sed -i 's/zelda/solaria/g' $file
   sed -i 's/rupee/gem/g' $file
done
echo "Renamed text."