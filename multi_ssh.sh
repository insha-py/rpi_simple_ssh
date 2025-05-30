#!/bin/bash

# Multi-SSH Terminal Launcher for Bash
# This script opens multiple terminal windows for SSH connections to different devices

# Configuration - Edit these arrays to match your network devices
declare -A devices=(
    ["rpi_dawg2"]="dawg2@192.168.0.139" #dawg2
    ["rpi_dawg6"]="dawg6@192.168.0.142" 
)
# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' 

echo -e "${GREEN}Multi-SSH Terminal Launcher${NC}"
echo -e "${GREEN}===========================${NC}"
echo ""

# Function to detect the terminal emulator and open SSH connection
open_ssh_terminal() {
    local device_name="$1"
    local connection_string="$2"
    
    # Parse connection string (user@ip:port)
    local user_host=$(echo "$connection_string" | cut -d':' -f1)
    local port=$(echo "$connection_string" | cut -d':' -f2)
    
    local ssh_command="ssh -p $port $user_host"
    local window_title="SSH - $device_name ($user_host)"
    
    echo -e "${YELLOW}Opening terminal for $device_name...${NC}"
    
    # Detect the operating system and available terminal emulators
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        # Linux
        if command -v gnome-terminal >/dev/null 2>&1; then
            gnome-terminal --title="$window_title" -- bash -c "echo 'Connecting to $device_name...'; $ssh_command; exec bash"
        elif command -v konsole >/dev/null 2>&1; then
            konsole --title "$window_title" -e bash -c "echo 'Connecting to $device_name...'; $ssh_command; exec bash"
        elif command -v xterm >/dev/null 2>&1; then
            xterm -title "$window_title" -e bash -c "echo 'Connecting to $device_name...'; $ssh_command; exec bash" &
        else
            echo -e "${RED}No compatible terminal emulator found${NC}"
            return 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        osascript -e "tell application \"Terminal\" to do script \"echo 'Connecting to $device_name...'; $ssh_command\""
    elif [[ "$OSTYPE" == "msys" || "$OSTYPE" == "cygwin" ]]; then
        # Git Bash on Windows or Cygwin
        if command -v mintty >/dev/null 2>&1; then
            mintty -t "$window_title" -e bash -c "echo 'Connecting to $device_name...'; $ssh_command; exec bash" &
        else
            # Fall back to starting a new bash session
            bash -c "echo 'Connecting to $device_name...'; $ssh_command" &
        fi
    else
        echo -e "${RED}Unsupported operating system: $OSTYPE${NC}"
        return 1
    fi
    
    sleep 0.5  # Small delay to prevent overwhelming the system
}

# Function to show device menu
show_device_menu() {
    echo -e "${CYAN}Available devices:${NC}"
    local index=1
    for device_name in "${!devices[@]}"; do
        local connection="${devices[$device_name]}"
        echo -e "  ${WHITE}[$index] $device_name - $connection${NC}"
        ((index++))
    done
    echo -e "  ${GREEN}[A] Connect to ALL devices${NC}"
    echo -e "  ${RED}[Q] Quit${NC}"
    echo ""
}

# Convert associative array to indexed for easier access
device_names=($(printf '%s\n' "${!devices[@]}" | sort))

# Main menu loop
while true; do
    show_device_menu
    read -p "Select device(s) to connect to: " choice
    
    case "${choice^^}" in  # Convert to uppercase
        "A")
            echo -e "${GREEN}Opening terminals for all devices...${NC}"
            for device_name in "${device_names[@]}"; do
                open_ssh_terminal "$device_name" "${devices[$device_name]}"
            done
            echo -e "${GREEN}All terminals opened!${NC}"
            ;;
        "Q")
            echo -e "${YELLOW}Exiting...${NC}"
            break
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#device_names[@]}" ]; then
                local selected_device="${device_names[$((choice-1))]}"
                open_ssh_terminal "$selected_device" "${devices[$selected_device]}"
            else
                echo -e "${RED}Invalid selection. Please try again.${NC}"
            fi
            ;;
    esac
    
    if [[ "${choice^^}" != "Q" ]]; then
        echo ""
        read -p "Press Enter to continue or 'Q' to quit: " continue_choice
        if [[ "${continue_choice^^}" == "Q" ]]; then
            break
        fi
        clear
    fi
done

echo -e "${GREEN}Goodbye!${NC}" 