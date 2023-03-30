#!/bin/bash

# This script will scan a user's directories for the application menu for applications that are in the games category and output the list to the terminal.

echo "Scanning user directories for applications in the Games category..."

# Get the list of all applications in the Games category
games_list=$(find ~/ -name '*.app' | grep -i 'Games')

# Output the list of applications in the Games category
echo "List of applications in the Games category:"
echo "$games_list"