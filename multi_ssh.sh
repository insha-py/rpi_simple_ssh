#!/bin/bash

# Multi-SSH Terminal Launcher for Bash
# This script opens multiple terminal windows for SSH connections to different devices
# with automatic password entry and command execution

# Configuration - Edit these arrays to match your network devices
declare -A devices=(
    ["rpi_dawg2"]="dawg2@192.168.0.139" #dawg2
    ["rpi_dawg6"]="dawg6@192.168.0.142" 
)

# Configuration file for sensitive data (passwords, etc.)
CONFIG_FILE="ssh_config.conf"

# Password configuration - Will be loaded from config file
declare -A passwords=()

# Navigation and command configuration
DOWNLOADS_SUBFOLDER="your_subfolder_name"  # Replace with actual subfolder name in Downloads
SPECIFIC_COMMAND="echo 'Placeholder command - replace with your actual command'"  # Replace with your specific command

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

# Function to load configuration from file
load_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found.${NC}"
        echo -e "${YELLOW}Please ensure your ssh_config.conf file exists in the current directory.${NC}"
        return 1
    fi
    
    echo -e "${CYAN}Loading configuration from '$CONFIG_FILE'...${NC}"
    
    # Read the config file and populate arrays
    while IFS='=' read -r key value; do
        # Skip comments and empty lines
        [[ $key =~ ^[[:space:]]*# ]] && continue
        [[ -z $key ]] && continue
        
        # Remove leading/trailing whitespace
        key=$(echo "$key" | xargs)
        value=$(echo "$value" | xargs)
        
        # Handle special configuration variables
        if [[ "$key" == "DOWNLOADS_SUBFOLDER" ]]; then
            DOWNLOADS_SUBFOLDER="$value"
            echo -e "  ${GREEN}✓${NC} Downloads subfolder: ${WHITE}$value${NC}"
        elif [[ "$key" == "SPECIFIC_COMMAND" ]]; then
            SPECIFIC_COMMAND="$value"
            echo -e "  ${GREEN}✓${NC} Specific command: ${WHITE}$value${NC}"
        else
            # Assume it's a device password
            passwords["$key"]="$value"
            echo -e "  ${GREEN}✓${NC} Password configured for: ${WHITE}$key${NC}"
        fi
    done < "$CONFIG_FILE"
    
    echo -e "${GREEN}Configuration loaded successfully!${NC}"
    echo ""
    
    return 0
}

# Function to check if sshpass is installed
check_sshpass() {
    if ! command -v sshpass >/dev/null 2>&1; then
        echo -e "${RED}Error: sshpass is not installed${NC}"
        echo -e "${YELLOW}Please install sshpass first:${NC}"
        echo -e "  ${WHITE}Ubuntu/Debian: sudo apt-get install sshpass${NC}"
        echo -e "  ${WHITE}CentOS/RHEL: sudo yum install sshpass${NC}"
        echo -e "  ${WHITE}macOS: brew install sshpass${NC}"
        echo -e "  ${WHITE}Windows (Git Bash): Install through package manager or compile from source${NC}"
        return 1
    fi
    return 0
}

# Function to detect the terminal emulator and open SSH connection with automation
open_ssh_terminal() {
    local device_name="$1"
    local connection_string="$2"
    local password="$3"
    
    # Parse connection string (user@ip:port)
    local user_host=$(echo "$connection_string" | cut -d':' -f1)
    local port=$(echo "$connection_string" | cut -d':' -f2)
    
    # If no port specified, default to 22
    if [[ "$port" == "$user_host" ]]; then
        port="22"
    fi
    
    # Create a simpler automation script
    local automation_script="echo 'Connecting to $device_name at $user_host:$port...'; echo 'Password will be provided automatically'; sshpass -p '$password' ssh -p $port -o StrictHostKeyChecking=no -o ConnectTimeout=10 $user_host; echo 'SSH session ended. Press Enter to close...'; read"
    
    local window_title="SSH - $device_name ($user_host)"
    
    echo -e "${YELLOW}Opening automated terminal for $device_name...${NC}"
    echo -e "${CYAN}Debug: Connecting to $user_host:$port${NC}"
    
    # Raspberry Pi / Linux terminal detection with better fallbacks
    if command -v x-terminal-emulator >/dev/null 2>&1; then
        # Debian/Ubuntu default terminal alternative
        echo -e "${CYAN}Using system default terminal emulator...${NC}"
        x-terminal-emulator -T "$window_title" -e bash -c "$automation_script" &
    elif command -v lxterminal >/dev/null 2>&1; then
        # LXDE terminal (common on Raspberry Pi OS Lite)
        echo -e "${CYAN}Using LXTerminal...${NC}"
        lxterminal --title="$window_title" -e bash -c "$automation_script" &
    elif command -v gnome-terminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using GNOME Terminal...${NC}"
        gnome-terminal --title="$window_title" -- bash -c "$automation_script"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using XFCE Terminal...${NC}"
        xfce4-terminal --title="$window_title" -e bash -c "$automation_script"
    elif command -v mate-terminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using MATE Terminal...${NC}"
        mate-terminal --title="$window_title" -e bash -c "$automation_script"
    elif command -v konsole >/dev/null 2>&1; then
        echo -e "${CYAN}Using Konsole...${NC}"
        konsole --title "$window_title" -e bash -c "$automation_script"
    elif command -v xterm >/dev/null 2>&1; then
        echo -e "${CYAN}Using XTerm...${NC}"
        xterm -title "$window_title" -e bash -c "$automation_script" &
    elif command -v urxvt >/dev/null 2>&1; then
        echo -e "${CYAN}Using urxvt...${NC}"
        urxvt -title "$window_title" -e bash -c "$automation_script" &
    else
        echo -e "${RED}No compatible terminal emulator found${NC}"
        echo -e "${YELLOW}Trying fallback method - running in current terminal...${NC}"
        echo -e "${CYAN}Testing SSH connection:${NC}"
        echo ""
        echo "Target: $user_host:$port"
        echo "Device: $device_name"
        echo ""
        echo -e "${YELLOW}Press Enter to test SSH connection, or 'q' to skip:${NC}"
        read -r test_choice
        if [[ "${test_choice,,}" != "q" ]]; then
            echo "Testing SSH connection..."
            sshpass -p "$password" ssh -p $port -o StrictHostKeyChecking=no -o ConnectTimeout=10 $user_host "echo 'Connection test successful to $device_name!'; whoami; pwd; exit"
            if [[ $? -eq 0 ]]; then
                echo -e "${GREEN}SSH connection test passed!${NC}"
                echo -e "${YELLOW}Would you like to open an interactive SSH session now? (y/n):${NC}"
                read -r interactive_choice
                if [[ "${interactive_choice,,}" == "y" ]]; then
                    echo "Opening interactive SSH session..."
                    sshpass -p "$password" ssh -p $port -o StrictHostKeyChecking=no $user_host
                fi
            else
                echo -e "${RED}SSH connection test failed!${NC}"
                echo "Please check:"
                echo "1. Network connectivity to $user_host:$port"
                echo "2. SSH service running on target device"
                echo "3. Correct password in configuration"
                echo "4. Device is powered on and accessible"
            fi
        fi
        return 1
    fi
    
    sleep 1  # Delay to prevent overwhelming the system
}

# Function to show device menu
show_device_menu() {
    echo -e "${CYAN}Available devices (with automation):${NC}"
    local index=1
    for device_name in "${!devices[@]}"; do
        local connection="${devices[$device_name]}"
        local password_status=""
        if [[ -n "${passwords[$device_name]}" && "${passwords[$device_name]}" != "your_password_here" ]]; then
            password_status="${GREEN}[Password configured]${NC}"
        else
            password_status="${RED}[Password not configured]${NC}"
        fi
        echo -e "  ${WHITE}[$index] $device_name - $connection ${NC}$password_status"
        ((index++))
    done
    echo -e "  ${GREEN}[A] Connect to ALL devices (automated)${NC}"
    echo -e "  ${BLUE}[M] Manual SSH (original mode)${NC}"
    echo -e "  ${CYAN}[C] Edit configuration${NC}"
    echo -e "  ${RED}[Q] Quit${NC}"
    echo ""
    echo -e "${YELLOW}Current automation settings:${NC}"
    echo -e "  Downloads subfolder: ${WHITE}$DOWNLOADS_SUBFOLDER${NC}"
    echo -e "  Command to execute: ${WHITE}$SPECIFIC_COMMAND${NC}"
    echo ""
}

# Function for manual SSH (original functionality)
open_manual_ssh_terminal() {
    local device_name="$1"
    local connection_string="$2"
    
    # Parse connection string (user@ip:port)
    local user_host=$(echo "$connection_string" | cut -d':' -f1)
    local port=$(echo "$connection_string" | cut -d':' -f2)
    
    # If no port specified, default to 22
    if [[ "$port" == "$user_host" ]]; then
        port="22"
    fi
    
    local ssh_command="ssh -p $port $user_host"
    local window_title="SSH - $device_name ($user_host) - Manual"
    
    echo -e "${YELLOW}Opening manual terminal for $device_name...${NC}"
    echo -e "${CYAN}Debug: Manual connection to $user_host:$port${NC}"
    
    # Create a command that keeps the terminal open
    local manual_script="echo 'Connecting to $device_name at $user_host:$port...'; echo 'You will need to enter the password manually'; $ssh_command; echo 'SSH session ended. Press Enter to close...'; read"
    
    # Raspberry Pi / Linux terminal detection
    if command -v x-terminal-emulator >/dev/null 2>&1; then
        echo -e "${CYAN}Using system default terminal emulator...${NC}"
        x-terminal-emulator -T "$window_title" -e bash -c "$manual_script" &
    elif command -v lxterminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using LXTerminal...${NC}"
        lxterminal --title="$window_title" -e bash -c "$manual_script" &
    elif command -v gnome-terminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using GNOME Terminal...${NC}"
        gnome-terminal --title="$window_title" -- bash -c "$manual_script"
    elif command -v xfce4-terminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using XFCE Terminal...${NC}"
        xfce4-terminal --title="$window_title" -e bash -c "$manual_script"
    elif command -v mate-terminal >/dev/null 2>&1; then
        echo -e "${CYAN}Using MATE Terminal...${NC}"
        mate-terminal --title="$window_title" -e bash -c "$manual_script"
    elif command -v konsole >/dev/null 2>&1; then
        echo -e "${CYAN}Using Konsole...${NC}"
        konsole --title "$window_title" -e bash -c "$manual_script"
    elif command -v xterm >/dev/null 2>&1; then
        echo -e "${CYAN}Using XTerm...${NC}"
        xterm -title "$window_title" -e bash -c "$manual_script" &
    elif command -v urxvt >/dev/null 2>&1; then
        echo -e "${CYAN}Using urxvt...${NC}"
        urxvt -title "$window_title" -e bash -c "$manual_script" &
    else
        echo -e "${RED}No compatible terminal emulator found${NC}"
        echo -e "${YELLOW}Falling back to current terminal...${NC}"
        echo -e "${CYAN}Connecting manually in current terminal:${NC}"
        echo "Executing: $ssh_command"
        echo ""
        $ssh_command
        return 1
    fi
    
    sleep 0.5  # Small delay to prevent overwhelming the system
}

# Function to edit configuration
edit_config() {
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Configuration file '$CONFIG_FILE' not found.${NC}"
        echo -e "${YELLOW}Please ensure your ssh_config.conf file exists in the current directory.${NC}"
        return 1
    fi
    
    # Try to open with available Linux text editors
    if command -v nano >/dev/null 2>&1; then
        nano "$CONFIG_FILE"
    elif command -v vim >/dev/null 2>&1; then
        vim "$CONFIG_FILE"
    elif command -v vi >/dev/null 2>&1; then
        vi "$CONFIG_FILE"
    elif command -v gedit >/dev/null 2>&1; then
        gedit "$CONFIG_FILE"
    else
        echo -e "${RED}No text editor found. Please edit '$CONFIG_FILE' manually.${NC}"
        echo -e "${YELLOW}Install nano, vim, vi, or gedit to use this feature.${NC}"
        return 1
    fi
    
    # Reload configuration after editing
    load_config
}

# Load configuration at startup
load_config
CONFIG_LOADED=$?

# Check if sshpass is available for automated mode
SSHPASS_AVAILABLE=false
if check_sshpass; then
    SSHPASS_AVAILABLE=true
fi

# Convert associative array to indexed for easier access
device_names=($(printf '%s\n' "${!devices[@]}" | sort))

# Main menu loop
while true; do
    show_device_menu
    read -p "Select device(s) to connect to: " choice
    
    case "${choice^^}" in  # Convert to uppercase
        "A")
            if [[ "$CONFIG_LOADED" -ne 0 ]]; then
                echo -e "${RED}Please configure passwords first using option [C]${NC}"
            elif [[ "$SSHPASS_AVAILABLE" == "true" ]]; then
                echo -e "${GREEN}Opening automated terminals for all devices...${NC}"
                for device_name in "${device_names[@]}"; do
                    password="${passwords[$device_name]}"
                    if [[ -n "$password" && "$password" != "your_password_here" ]]; then
                        open_ssh_terminal "$device_name" "${devices[$device_name]}" "$password"
                    else
                        echo -e "${RED}Skipping $device_name - password not configured${NC}"
                    fi
                done
                echo -e "${GREEN}All automated terminals opened!${NC}"
            else
                echo -e "${RED}Automated mode not available - sshpass not installed${NC}"
            fi
            ;;
        "M")
            echo -e "${CYAN}Manual SSH mode selected${NC}"
            show_device_menu
            read -p "Select device for manual connection: " manual_choice
            if [[ "$manual_choice" =~ ^[0-9]+$ ]] && [ "$manual_choice" -ge 1 ] && [ "$manual_choice" -le "${#device_names[@]}" ]; then
                selected_device="${device_names[$((manual_choice-1))]}"
                open_manual_ssh_terminal "$selected_device" "${devices[$selected_device]}"
            else
                echo -e "${RED}Invalid selection for manual mode.${NC}"
            fi
            ;;
        "C")
            edit_config
            CONFIG_LOADED=0
            ;;
        "Q")
            echo -e "${YELLOW}Exiting...${NC}"
            break
            ;;
        *)
            if [[ "$choice" =~ ^[0-9]+$ ]] && [ "$choice" -ge 1 ] && [ "$choice" -le "${#device_names[@]}" ]; then
                selected_device="${device_names[$((choice-1))]}"
                password="${passwords[$selected_device]}"
                if [[ "$CONFIG_LOADED" -eq 0 ]] && [[ "$SSHPASS_AVAILABLE" == "true" ]] && [[ -n "$password" && "$password" != "your_password_here" ]]; then
                    open_ssh_terminal "$selected_device" "${devices[$selected_device]}" "$password"
                else
                    echo -e "${YELLOW}Using manual mode for $selected_device${NC}"
                    open_manual_ssh_terminal "$selected_device" "${devices[$selected_device]}"
                fi
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