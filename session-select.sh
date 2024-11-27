#!/bin/bash

# Display options to the user
echo "Please choose a session type:"
echo "1) plasma-wayland-persistent"
echo "2) plasma-x11-persistent"
echo "3) plasma"
echo "4) gamescope"

# Read user input
read -p "Enter the number corresponding to your choice (1-4): " choice

# Map the user's choice to the corresponding session type
case $choice in
    1)
        option="plasma-wayland-persistent"
        ;;
    2)
        option="plasma-x11-persistent"
        ;;
    3)
        option="plasma"
        ;;
    4)
        option="gamescope"
        ;;
    *)
        echo "Invalid choice. Exiting."
        exit 1
        ;;
esac

# Run the command with the chosen option
steamos-session-select "$option"
