#!/bin/bash

echo "This script will add games to your Sunshine application based on your application menu."

# Create a temporary file to store the list of game applications
tmpfile=$(mktemp)

# Create a temporary directory to store the game art images
tmpdir=$(mktemp -d)

# Scan /usr/share/applications/ and /usr/local/share/applications/ for .desktop files
# that have "Categories=Game" defined.
find /usr/share/applications/ /usr/local/share/applications/ -type f -name '*.desktop' \
    -exec grep -H -e 'Categories=.*Game' -e '^Name=' {} \; | \
    while read line ; do
        case "$line" in
            *".desktop"* )
                desktopFile=$(echo "$line" | cut -d: -f1)
                ;;
            *"Name="* )
                appName=$(echo "$line" | cut -d= -f2)
                if [ -n "$desktopFile" ]; then
                    echo "Adding game $appName from $desktopFile"
                    # Get the game ID from SteamGridDB API
                    gameId=$(curl --silent 'https://www.steamgriddb.com/api/v2/search/autocomplete?term='"${appName}"'&types=game' | jq -r '.[0] | .id')
                    if [ -n "$gameId" ]; then
                        # Download the game art from SteamGridDB API
                        curl --silent "https://www.steamgriddb.com/api/v2/grids/game/${gameId}?dimensions=600x900" | jq -r '.data[0].attributes.url' | xargs -I {} curl --silent -o "${tmpdir}/${gameId}.jpg" {}
                        # Add the game to the temporary file with its image path
                        echo "$desktopFile,$appName,${tmpdir}/${gameId}.jpg" >> "$tmpfile"
                    else
                        echo "Game $appName not found in SteamGridDB."
                    fi
                    desktopFile=""
                fi
                ;;
        esac
    done

# Scan /home/$(whoami)/.local/share/applications/ for .desktop files
# that have "Categories=Game" defined.
find "/home/$(whoami)/.local/share/applications/" -type f -name '*.desktop' \
    -exec grep -H -e 'Categories=.*Game' -e '^Name=' {} \; | \
    while read line ; do
        case "$line" in
            *".desktop"* )
                desktopFile=$(echo "$line" | cut -d: -f1)
                ;;
            *"Name="* )
                appName=$(echo "$line" | cut -d= -f2)
                if [ -n "$desktopFile" ]; then
                    echo "Adding game $appName from $desktopFile"
                    # Get the game ID from SteamGridDB API
                    gameId=$(curl --silent 'https://www.steamgriddb.com/api/v2/search/autocomplete?term='"${appName}"'&types=game' | jq -r '.[0] | .id')
                    if [ -n "$gameId" ]; then
                        # Download the game art from SteamGridDB API
                        curl --silent "https://www.steamgriddb.com/api/v2/grids/game/${gameId}?dimensions=600x900" | jq -r '.data[0].attributes.url' | xargs -I {} curl --silent -o "${tmpdir}/${gameId}.jpg" {}
                        # Add the game to the temporary file with its image path
                        echo "$desktopFile,$appName,${tmpdir}/${gameId}.jpg" >> "$tmpfile"
                    else
                        echo "Game $appName not found in SteamGridDB."
                    fi
                    desktopFile=""
                fi
                ;;
        esac
    done

# Use Sunshine's CLI tool to add each game in the temporary file to Sunshine
while IFS="," read -r desktopFile appName imagePath || [ -n "$desktopFile" ]
do
  cat "${desktopFile}" | sunshine app add --name "$appName" --logo "$imagePath" --source -
done < "$tmpfile"

# Remove the temporary file and directory
rm "$tmpfile"
rm -r "$tmpdir"
