#!/bin/zsh

# ============================================
# Script Name:     init_template.sh
# Description:     This script initializes template VMs
# Author:          HKO
# Version:         1.1
# Last Updated:    2024-09-10
# ============================================

# Usage:
#   -- The script is automatically loaded via ~/Library/LaunchAgents/com.admin.init-template.plist

# Options:
#   -h, --help        Display this help message and exit
#   -v, --version     Show version information


# =============================================================
# ===================== VARIABLE DECLARATIONS =================
# =============================================================

# Script version
version="1.1"

# Color definitions
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

YAML_FILE="$HOME/config.yaml"

# Log file for init.sh
LOG="$HOME/init.log"

# Terminal session recording log file
RECORDING_LOG="$HOME/terminal_session.log"

# init marker file 
INIT_TEMPLATE_MARKER_FILE="$HOME/.init_template_marker_file_ran"

BREW_CMD="$HOME/homebrew/bin/brew"

# ============================================================
# ===================== FUNCTION DEFINITIONS =================
# ============================================================

# ============================================================
# Function: log_message
# Description: Logs messages with a timestamp, script name, and
# function name. Messages containing "error" are printed in red.
#
# Parameters:
# - $1: The message to log.
#
# Steps:
# 1. Retrieve the message to log from the first argument.
# 2. Get the name of the current script.
# 3. Get the name of the current function from the call stack.
# 4. Define color codes for red and reset.
# 5. Check if the message contains "error" or "Error".
#    - If it does, print the message in red.
#    - If it doesn't, print the message in the default color.
# 6. Append the message to the log file.
#
# Globals:
# - log: The path to the log file.
#
# Note: Ensure that the log variable is defined before calling
#       this function.
# ============================================================
log_message() {
    # 1. Retrieve the message to log from the first argument
    local message="$1"
    local exit_code="${2:-0}"  # Default to 0 if no exit code is provided
    # 2. Get the name of the current script
    local script_name="$(basename "${(%):-%x}")"
    local funcname="unknown"
    local line_number="unknown"
    # 3. Get the name of the current function from the call stack
    local current_function="${funcstack[2]}"
    if [[ ${#funcstack[@]} -gt 1 ]]; then
        funcname="${funcstack[2]}"
        line_number="$LINENO"
    fi    
    # 4. Define color codes for red and reset
    local color_red="\033[31m"
    local color_yellow="\033[33m"
    local color_cyan="\033[36m"
    local color_reset="\033[0m"
    
    # 5. Check if the message contains "error" or "Error" and append to log
    if [[ "$message" == *"error"* || "$message" == *"Error"* || "$exit_code" -ne 0 ]]; then
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${color_cyan}[$script_name]${color_reset}@${color_yellow}[$funcname:$line_number]${color_reset} ${color_red}$message (exit code: $exit_code)${color_reset}" | tee -a "$LOG"
    else
        echo -e "$(date '+%Y-%m-%d %H:%M:%S') ${color_cyan}[$script_name]${color_reset}@${color_yellow}[$funcname:$line_number]${color_reset} $message" | tee -a "$LOG"
    fi
}

# Function to reset the log file
reset_logfile() {
    if [ -f "$LOG" ]; then
        log_message "Logfile exists. Deleting..." 1
        rm -f "$LOG"
    # check RECORDING_LOG
    elif [ -f "$RECORDING_LOG" ]; then
        log_message "Recording log exists. Deleting..." 1
        rm -f "$RECORDING_LOG"
    else
        log_message "Logfile didn't exist.. Continuing..."
    fi
}


# ============================================================
# Function: show_welcome
# Description: Displays a welcome message along with an ASCII
# art logo. This function is intended to greet users when they
# run the script.
# ============================================================
show_welcome() {
    # ASCII Art Logo
    echo -e "${GREEN}"
    echo " __          __        _    _           _     "
    echo " \ \        / /       | |  | |         | |    "
    echo "  \ \  /\  / /__  _ __| | _| |     __ _| |__  "
    echo "   \ \/  \/ / _ \| '__| |/ / |    / _\` | '_ \ "
    echo "    \  /\  / (_) | |  |   <| |___| (_| | |_) |"
    echo "     \/  \/ \___/|_|  |_|\_\______\__,_|_.__/ "
    echo -e "${NC}"

    # Welcome message
    echo -e "${YELLOW}Welcome to init_template.sh v${version}${NC}"
    echo "-----------------------------------"
    echo "This script initializes template VMs"
}

# ============================================================
# Function: show_help
# Description: Displays the help message for the script,
# including usage instructions and available options.
# ============================================================
show_help() {
    echo "Usage: $0 [options]"
    echo
    echo "Options:"
    echo "  -h, --help        Display this help message and exit"
    echo "  -v, --version     Show version information"
    echo
}

# ============================================================
# Function: show_version
# Description: Displays the version information of the script.
# ============================================================
show_version() {
    echo "Version: $version"
}

# ============================================================
# Function: expand_vars
# Description: Expands environment variables within a given
# string. This function evaluates the string as a shell command
# to replace any environment variables with their values.
#
# Parameters:
# - $1: The string containing environment variables to expand.
#
# Steps:
# 1. Evaluate the input string to expand environment variables.
# 2. Output the expanded string.
#
# Globals:
# - None
#
# Note: This function requires the input string to be passed as
#       an argument.
# ============================================================
expand_vars() {
  local str="$1"
  str=$(eval echo "$str")
  echo "$str"
}

# ============================================================
# Function: install_xcode_command_line_utils
# Description: Installs the Xcode Command Line Tools, which are
# necessary for compiling and installing various software packages
# on macOS.
#
# Steps:
# 1. Log the start of the Xcode Command Line Tools check.
# 2. Check if the Xcode Command Line Tools are already installed
#    by looking for the presence of the 'xcode-select' command.
#    - If the tools are installed, log a message indicating they
#      are already installed and exit the function.
# 3. If the tools are not installed, initiate the installation
#    process:
#    - Create a temporary file to signal the installation process.
#    - Retrieve the product name for the Command Line Tools using
#      the 'softwareupdate' command.
#    - Log the product name.
#    - Install the Command Line Tools using the 'softwareupdate'
#      command with the retrieved product name.
# 4. Validate the installation:
#    - If the installation is successful, log a success message.
#    - If the installation fails, log an error message and exit
#      the script with a status code of 1.
#
# Globals:
# - None
#
# Note: This function requires an active internet connection to
#       download the Xcode Command Line Tools.
# ============================================================
install_xcode_command_line_utils() {
    # 1. Log the start of the Xcode Command Line Tools check
    log_message "Checking Xcode CLI tools"
 
    # 2. Check if the Xcode Command Line Tools are already installed
    if ! xcode-select -p &>/dev/null; then
        echo "Installing the latest version of Xcode Command Line Tools non-interactively..."
        touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
        
        # Get the latest Command Line Tools version available
        PROD=$(softwareupdate -l |
            grep -E '\* Command Line Tools' |
            awk -F"*" '{print $2}' |
            sed -e 's/^ *//' |
            sed -e 's/^Label: //' | # Remove "Label: " prefix
            sort -V |
            tail -n 1) # Get the latest version

        if [ -n "$PROD" ]; then
            echo "Installing $PROD..."
            softwareupdate -i "'$PROD'" --verbose
        else
            echo "No Command Line Tools available for installation."
        fi

        rm /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress
    else
        echo "Xcode Command Line Tools are already installed."
    fi
}

# ============================================================
# Function: install_homebrew
# Description: Installs Homebrew, a package manager for macOS,
# if it is not already installed. This function ensures that
# Homebrew is available for installing other software packages.
#
# Steps:
# 1. Check if Homebrew is already installed by looking for the
#    Homebrew directory in the user's home directory.
#    - If Homebrew is installed, log a message indicating it is
#      already installed and create a marker file if it doesn't exist.
#    - If the marker file exists, log the last update date.
#    - Add Homebrew to the PATH and source the .zshenv file.
#    - Declare necessary variables and exit the function.
# 2. If Homebrew is not installed, download and extract the
#    Homebrew installation tarball to the specified directory.
# 3. Validate the installation by checking if the 'brew' command
#    is available after the script runs.
#    - If the installation is successful, log a success message,
#      update Homebrew, and install the 'yq' tool.
#    - Set the Cask installation directory
#    - Add Homebrew to the PATH and source the .zshenv file.
#    - Declare necessary variables and set appropriate permissions.
#    - Create a marker file to indicate successful installation.
#    - If the installation fails, log an error message and exit
#      the script with a status code of 1.
#
# Globals:
# - BREW_CMD: The command to run Homebrew.
#   Example: ${HOME}/homebrew/bin/brew
#
# Note: This function requires an active internet connection to
#       download the Homebrew installation script.
# ============================================================
install_homebrew() {
    local marker_file=".install_homebrew_ran"
    local homebrew_dir="$HOME/homebrew"

    # 1. Check if Homebrew is already installed by looking for the Homebrew directory
    # if [ -d "$homebrew_dir" ]; then
    #     if [ ! -f "$marker_file" ]; then
    #         # If Homebrew is installed, log a message indicating it is already installed
    #         log_message "Homebrew already installed, creating marker file..."

    #         # Create a marker file to indicate that Homebrew is installed
    #         create_marker_file "$marker_file"
    #     else
    #         # If the marker file exists, log the last update date
    #         local last_update_date=$(cat "$marker_file")
    #         # Log the last update date of Homebrew
    #         log_message "Homebrew already installed and updated on $last_update_date"
    #     fi

    #     # Add Homebrew to the PATH and source the .zshenv file
    #     echo 'eval "$('"$BREW_CMD"' shellenv)"' >> "$HOME/.zshenv"
    #     source "$HOME/.zshenv"

    #     # Declare necessary variables and exit the function
    #     declare_variables
    #     return
    # fi

    # Remove existing Homebrew directory and marker file if they exist
    if [ -d "$homebrew_dir" ]; then
        log_message "Removing existing Homebrew directory..."
        rm -rf "$homebrew_dir"
    fi

    if [ -f "$marker_file" ]; then
        log_message "Removing existing marker file..."
        rm "$marker_file"
    fi


    log_message "Installing Homebrew..."

    # 2. If Homebrew is not installed, download and extract the Homebrew installation tarball
    mkdir -p "$homebrew_dir" && curl -L https://github.com/Homebrew/brew/tarball/master | tar xz --strip-components 1 -C "$homebrew_dir"

    if [ $? -eq 0 ]; then
        # if the installation was successful, log a success message
        log_message "Homebrew installed successfully."

        # Update Homebrew and install the 'yq' tool
        "$BREW_CMD" update --force --quiet
        "$BREW_CMD" install yq

        # Set the Cask installation directory:
        echo 'export HOMEBREW_CASK_OPTS="--appdir=$HOME/Applications"' >> "$HOME/.zshenv"

        # Add Homebrew to the PATH and source the .zshenv file
        echo 'eval "$('"$BREW_CMD"' shellenv)"' >> "$HOME/.zshenv"
        source "$HOME/.zshenv"

        # Declare necessary variables and set appropriate permissions
        declare_variables

        # Set permissions for the Homebrew directories
        chmod -R go-w "$("$BREW_CMD" --prefix)/share/zsh"

        # Create a marker file to indicate successful installation
        create_marker_file "$marker_file"
    else
        log_message "Failed to install Homebrew. Exiting..." 1
        exit 1
    fi
}

# ============================================================
# Function: declare_variables
# Description: Declares and initializes various global variables
# used throughout the script. These variables include paths,
# URLs, commands, and other configuration settings.
#
# Steps:
# 1. Check if Homebrew is installed.
#    - If not installed, skip the variable declaration.
# 2. Retrieve values from the YAML configuration file using 'yq'.
#    - Retrieve the INITREPO_URL, TARGET_DIR, XDG_CONFIG_HOME,
#      ZDOTDIR, GIT_DIR, and API_URL values.
# 3. Expand environment variables in the retrieved values.
#    - Use the 'expand_vars' function to evaluate and expand
#      environment variables within the retrieved values.
# 4. Log the retrieved and expanded values for debugging purposes.
#
# Globals:
# - YAML_FILE: Path to the YAML configuration file.
#   Example: ${HOME}/config.yaml
# - INITREPO_URL: URL of the initial repository.
#   Example: "https://git.havkros.duckdns.org:4443/hko/init"
# - TARGET_DIR: Path to the target directory.
#   Example: ${HOME}/init
# - XDG_CONFIG_HOME: Path to the user-specific configuration directory.
#   Example: ${HOME}/.config
# - ZDOTDIR: Path to the Zsh configuration directory.
#   Example: ${XDG_CONFIG_HOME}/zsh
# - GIT_DIR: Path to the Git configuration directory.
#   Example: ${XDG_CONFIG_HOME}/git
# - API_URL: URL of the GitHub API for the latest Nextcloud release.
#   Example: "https://api.github.com/repos/nextcloud/desktop/releases/latest"
#
# Note: Ensure that the YAML_FILE variable is set before running
#       this function.
# ============================================================
declare_variables() {

    # 1. Check if Homebrew is installed
    if command -v brew >/dev/null 2>&1; then

        # 2. Retrieve values from the YAML configuration file using 'yq'
        INITREPO_URL=$(yq eval '.settings.initrepo.url' "$YAML_FILE")
        TARGET_DIR=$(yq eval '.settings.target_dir.path' "$YAML_FILE")
        XDG_CONFIG_HOME=$(yq eval '.settings.xdg_config_home.path' "$YAML_FILE")
        ZDOTDIR=$(yq eval '.settings.zdotdir.path' "$YAML_FILE")
        GIT_DIR=$(yq eval '.settings.git_dir.path' "$YAML_FILE")
        API_URL=$(yq eval '.settings.git_api_url.url' "$YAML_FILE")

        # 3. Expand environment variables in the retrieved values
        INITREPO_URL=$(expand_vars "$INITREPO_URL")
        TARGET_DIR=$(expand_vars "$TARGET_DIR")
        XDG_CONFIG_HOME=$(expand_vars "$XDG_CONFIG_HOME")
        ZDOTDIR=$(expand_vars "$ZDOTDIR")
        GIT_DIR=$(expand_vars "$GIT_DIR")
        API_URL=$(expand_vars "$API_URL")

        # 4. Log the retrieved and expanded values for debugging purposes
        log_message "Retrieved and expanded values from the YAML file:"
        log_message "- INITREPO_URL: $INITREPO_URL"
        log_message "- TARGET_DIR: $TARGET_DIR"
        log_message "- XDG_CONFIG_HOME: $XDG_CONFIG_HOME"
        log_message "- ZDOTDIR: $ZDOTDIR"
        log_message "- GIT_DIR: $GIT_DIR"
        log_message "- API_URL: $API_URL"
    fi
}

# ============================================================
# Function: install_software
# Description: Installs various software packages and tools
# based on a predefined list or configuration.
#
# Steps:
# 1. Log the start of the software installation process.
# 2. Define the list of software packages to be installed.
# 3. Iterate over each software package in the list.
# 4. Check if the software package is already installed.
#    - If installed, log a message indicating it is already installed.
#    - If not installed, attempt to install the software package.
# 5. Log the success or failure of each installation attempt.
# 6. Log the completion of the software installation process.
#
# Globals:
# - SOFTWARE_LIST: An array or list of software packages to be installed.
#   Example: ("git" "node" "python3" "docker")
#
# Note: Ensure that the SOFTWARE_LIST variable is set before running
#       this function.
# ============================================================
install_software() {

    # 1. Log the start of the software installation process
    log_message "Installing software packages..."

    # 2. Define the list of software packages to be installed
    typeset -A applications

    num_entries=$(yq eval '.applications | length' "$YAML_FILE")

    # 3. Iterate over each software package in the list
    for i in $(seq 0 $(($num_entries - 1))); do
        
        name=$(yq eval ".applications[$i].name" "$YAML_FILE")
        directory=$(yq eval ".applications[$i].directory" "$YAML_FILE")
        type=$(yq eval ".applications[$i].type" "$YAML_FILE")
        directory=$(expand_vars "$directory")

        if [ "$type" != "native" ]; then
            # add to applications array
            applications[$name]="name=$name directory=$directory type=$type"
        fi

    done

    log_message "Installing software using Homebrew..."

    # Iterate over each application in the applications array defined above
    for package in ${(k)applications}; do

        log_message "Installing $package..."

        # 4. Check if the software package is already installed

        # Check if the package is a cask
        if $BREW_CMD info --cask "$package" &>/dev/null; then
            log_message "$package is a cask. Installing with --cask..."
            $BREW_CMD install --cask "$package"

            if [ $? -eq 0 ]; then
                # 5. Log a message indicating the package was installed successfully
                log_message "$package installed successfully."
            else
                # 5. Log an error message if the installation fails
                log_message "Failed to install $package." 1
            fi
        # Check if the package is a formula
        elif $BREW_CMD info "$package" &>/dev/null; then
            log_message "$package is a formula. Installing..."
            $BREW_CMD install "$package"

            if [ $? -eq 0 ]; then
                # 5. Log a message indicating the package was installed successfully
                log_message "$package installed successfully."
            else
                # 5. Log an error message if the installation fails
                log_message "Failed to install $package." 1
            fi
        else
            # 5. Log a message if the package is not available as a formula or cask
            log_message "$package is not available as a formula or cask." 1
        fi
    done

    # 6. Log the completion of the software installation process
    log_message "Software packages installed..."
}

# ============================================================
# Function: configure_software
# Description: Configures various software settings and installs
# Visual Studio Code extensions based on a YAML configuration file.
#
# Steps:
# 1. Add Visual Studio Code to the PATH if it is installed.
#    - Check if Visual Studio Code is installed.
#    - If installed, add the 'code' command to the PATH by
#      appending the appropriate line to the .zshrc file.
#    - Log messages indicating whether the line was added or
#      already exists.
# 2. Install Visual Studio Code extensions.
#    - Retrieve the number of extensions listed in the YAML
#      configuration file.
#    - Log the number of extensions to be installed.
#    - Iterate over each extension in the list.
#    - Check if the extension is already installed.
#    - If not installed, attempt to install the extension and
#      log the success or failure of the installation.
#    - Wait for 1 second before installing the next extension.
#
# Globals:
# - ZDOTDIR: Directory for Zsh configuration files.
#   Example: ${XDG_CONFIG_HOME}/zsh
# - YAML_FILE: Path to the YAML configuration file containing
#   the list of Visual Studio Code extensions.
#
# Note: Ensure that the ZDOTDIR and YAML_FILE variables are set
#       before running this function.
# ============================================================
configure_software() {


    local config_line='export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"'

    # 1. Add Visual Studio Code to the PATH if it is installed

    # Check if Visual Studio Code is installed
    if [ -d "/Applications/Visual Studio Code.app" ]; then
        log_message "Visual Studio Code is installed. Adding 'code' to PATH..."

        # Check if the line is already in the .zshrc file
        if ! grep -Fxq "$config_line" "$ZDOTDIR/.zshrc"; then

            # If not, append the line to the .zshrc file
            echo "$config_line" >> "$ZDOTDIR/.zshrc"

            # Log a message indicating that the line was added
            log_message "Added '$config_line' to $ZDOTDIR/.zshrc"
        else
            # Log a message indicating that the line already exists
            log_message "'$config_line' is already in $ZDOTDIR/.zshrc" 1
        fi
    fi

    # 2. Install Visual Studio Code extensions

    # Retrieve the number of extensions listed in the YAML configuration file
    num_entries=$(yq eval '.vscode-extensions | length' "$YAML_FILE")

    # Log the number of extensions to be installed
    log_message "Number of entries (vscode-extensions.name): $num_entries"

    # Iterate over each extension in the list
    for i in $(seq 0 $(($num_entries - 1))); do
        name=$(yq eval ".vscode-extensions[$i].name" "$YAML_FILE")

        # Check if the extension is already installed
        if code --list-extensions | grep -q "^$name$"; then
            log_message "Extension $name is already installed." 1
        else
            log_message "Installing Visual Studio Code extension: $name ..."

            # Attempt to install the extension
            if code --install-extension "$name"; then

                # Log the success or failure of the installation
                log_message "Successfully installed $name."
                log_message "Waiting for 1 second before installing the next extension..."

                # Wait for 1 second before installing the next extension
                sleep 1
            else
                # Log an error message if the installation fails
                log_message "Failed to install $name. Continuing with the next extension..." 1
            fi
        fi

    done

}

# ============================================================
# Function: install_nextcloud
# Description: Installs the Nextcloud application without
# requiring sudo/admin permissions by downloading the latest
# release from GitHub and placing it in the user's Applications
# directory.
#
# Steps:
# 1. Log the start of the installation process.
# 2. Define necessary directories for downloads and applications.
# 3. Retrieve the latest release information from the GitHub API.
# 4. Validate the JSON response to ensure it contains release information.
#    - If the response is invalid, log an error message and exit.
# 5. Create necessary directories if they don't exist.
# 6. Clean the JSON response to remove control characters.
# 7. Extract the latest version number from the JSON response.
# 8. Construct the download URL for the .pkg file based on the version number.
# 9. Define the package file name and path.
# 10. Download the .pkg file to the specified path.
# 11. Validate the download and log the success or failure.
# 12. Install the .pkg file to the Applications directory.
# 13. Log the completion of the installation process.
#
# Globals:
# - API_URL: The URL of the GitHub API to retrieve the latest release information.
#   Example: "https://api.github.com/repos/nextcloud/desktop/releases/latest"
# - DOWNLOADS_DIR: Directory where the .pkg file will be downloaded.
#   Example: ${HOME}/Downloads
# - APPLICATION_DIR: Directory where the application will be installed.
#   Example: ${HOME}/Applications
#
# Note: Ensure that the API_URL, DOWNLOADS_DIR, and APPLICATION_DIR
#       variables are set before running this function.
# ============================================================
install_nextcloud() {

    # 1. Log the start of the installation process
    log_message "Installing Nextcloud outside of Homebrew to avoid sudo/admin permissions..."

    # 2. Define necessary directories for downloads and applications
    DOWNLOADS_DIR="$HOME/Downloads"
    EXTRACT_DIR="$DOWNLOADS_DIR/output"
    APPLICATION_DIR="$HOME/Applications"

    # 3. Retrieve the latest release information from the GitHub API
    LATEST_RELEASE_JSON=$(curl -s "$API_URL")

    # 4. Validate the JSON response to ensure it contains release information
    if [ -z "$LATEST_RELEASE_JSON" ]; then
        # If the response is invalid, log an error message and exit
        log_message "Failed to retrieve release information. Exiting." 1
        exit 1
    fi

    # 5. Create necessary directories if they don't exist
    mkdir -p "$APPLICATION_DIR"

    # 6. Clean the JSON response to remove control characters
    CLEAN_JSON=$(echo "$LATEST_RELEASE_JSON" | tr -d '\000-\031')

    # 7. Extract the latest version number from the JSON response
    LATEST_VERSION=$(echo "$CLEAN_JSON" | jq -r '.tag_name' | sed 's/^v//' | tr -d '\n' | sed 's/-/_/g')
    log_message "Latest version extracted: $LATEST_VERSION"

    # 8. Construct the download URL for the .pkg file based on the version number
    PKG_URL="https://github.com/nextcloud-releases/desktop/releases/download/v${LATEST_VERSION}/Nextcloud-${LATEST_VERSION}.pkg"

    # 9. Define the package file name and path
    PKG_NAME="Nextcloud-${LATEST_VERSION}.pkg"
    PKG_PATH="$DOWNLOADS_DIR/$PKG_NAME"

    log_message "Downloading Nextcloud ${LATEST_VERSION}..."
    # 10. Download the .pkg file to the specified path
    if ! curl -L -o "$PKG_PATH" "$PKG_URL"; then
        # 11. Validate the download and log the success or failure
        log_message "Failed to download the .pkg file. Exiting." 1
        exit 1
    fi

    log_message "Extracting the .pkg file..."

    # 12. Install the .pkg file to the Applications directory
    pkgutil --expand "$PKG_PATH" "$EXTRACT_DIR"

    PAYLOAD_PATH="$EXTRACT_DIR/Nextcloud.pkg/Payload"

    if [ ! -f "$PAYLOAD_PATH" ]; then
        log_message "Payload file not found. Exiting." 1
    fi

    # The Payload is a compressed archive that contains the .app, so we need to extract it.
    # Inside the Payload file there already is a Applications/ directory containing the app.
    # This means that when extracting to $HOME it will automatically be extracted to $HOME/Applications
    bsdtar -xvf "$PAYLOAD_PATH" -C "$HOME"

    log_message "Cleaning up..."

    rm -rf "$PKG_PATH" "$EXTRACT_DIR"

    # 13. Log the completion of the installation process
    log_message "Installation complete. Nextcloud.app is located in $APPLICATION_DIR."
}

# ============================================================
# Function: configure_zsh
# Description: Configures the Zsh shell environment by ensuring
# Zsh is installed, creating necessary directories, copying
# configuration files, and sourcing them.
#
# Steps:
# 1. Check if Zsh is installed.
#    - If not installed, log a message and exit the script.
# 2. Create necessary folders if they don't exist.
# 3. Define the zshenv file path.
# 4. Copy the zshenv file from the target directory to the home
#    directory.
#    - Log a success message if the copy is successful.
#    - Log an error message if the copy fails.
# 5. Append the Homebrew shell environment initialization to
#    the zshenv file.
# 6. Source the zshenv and zshrc files to apply the configuration.
#
# Globals:
# - XDG_CONFIG_HOME: Directory for user-specific configuration files.
#   Example: ${HOME}/.config
# - ZDOTDIR: Directory for Zsh configuration files.
#   Example: ${XDG_CONFIG_HOME}/zsh
# - GIT_DIR: Directory for Git configuration files.
#   Example: ${XDG_CONFIG_HOME}/git
# - TARGET_DIR: Directory containing the source zshenv file.
#   Example: ${HOME}/init
#
# Note: Ensure that the XDG_CONFIG_HOME, ZDOTDIR, GIT_DIR, and
#       TARGET_DIR variables are set before running this function.
# ============================================================
configure_zsh() {

    # 1. Check if Zsh is installed
    if ! command -v zsh &> /dev/null; then
        log_message "zsh is not installed. Please install zsh and try again." 1
        exit 1
    fi

    # 2. Create necessary folders if they don't exist
    mkdir -p "$XDG_CONFIG_HOME"
    mkdir -p "$ZDOTDIR"
    mkdir -p "$GIT_DIR"

    # 3. Define the zshenv file path
    ZSHENV_FILE="$HOME/.zshenv"

    log_message "Copying $TARGET_DIR/zsh/.zshenv to $HOME/.zshenv ..."
    # 4. Copy the zshenv file from the target directory to the home directory
    cp "$TARGET_DIR/zsh/.zshenv" "$HOME/.zshenv"

    if [ $? -eq 0 ]; then
        # Log a success message if the copy is successful
        log_message "Copied $TARGET_DIR/zsh/.zshenv to $HOME/.zshenv successfully."
    else
        # Log an error message if the copy fails
        log_message "Failed to copy $TARGET_DIR/zsh/.zshenv to $HOME/.zshenv." 1
    fi

    # 5. Append the Homebrew shell environment initialization to the zshenv file
    echo 'eval "$('"$BREW_CMD"' shellenv)"' >> "$HOME/.zshenv"

    # 6. Source the zshenv and zshrc files to apply the configuration
    source $ZSHENV_FILE
    source $ZDOTDIR/.zshrc
}

# ============================================================
# Function: clone_init_repo
# Description: Clones a specified Git repository into a target
# directory. If the target directory already exists, it will
# be deleted before cloning.
#
# Steps:
# 1. Check if the target directory already exists.
#    - If it exists, log a message and delete the directory.
# 2. Clone the repository from the URL specified in the
#    INITREPO_URL variable to the target directory.
# 3. Check if the cloning process was successful.
#    - If successful, log a success message.
#    - If unsuccessful, log an error message and exit the
#      script with a status code of 1.
#
# Globals:
# - TARGET_DIR: The directory where the repository will be
#   cloned.
# - INITREPO_URL: The URL of the repository to be cloned.
#
# Note: Ensure that the INITREPO_URL and TARGET_DIR variables
#       are set before running this function.
# ============================================================
clone_init_repo() {

    # 1. Check if the target directory already exists
    if [ -d "$TARGET_DIR" ]; then
        # If it exists, log a message and delete the directory
        log_message "Directory '$TARGET_DIR' already exists. Deleting..." 1
        rm -rf "$HOME/init"
    fi


    log_message "Cloning repository $INITREPO_URL to $TARGET_DIR ..."

    # 2. Clone the repository from the URL to the target directory
    git clone "$INITREPO_URL" "$TARGET_DIR"

    # 3. Check if the cloning process was successful
    if [ $? -eq 0 ]; then
        # If successful, log a success message
        log_message "Repository $INITREPO_URL successfully cloned into '$TARGET_DIR'."
    else
        # If unsuccessful, log an error message and exit the script with a status code of 1
        log_message "Failed to clone $INITREPO_URL. Please check the URL and your network connection." 1
        exit 1
    fi

}


# ============================================================
# Function: add_to_macos_dock
# Description: Adds specified applications to the macOS Dock
# using dockutil. The applications and their properties are
# retrieved from a YAML file.
#
# Steps:
# 1. Define an associative array to store application properties.
# 2. Retrieve the list of applications from the YAML file.
# 3. Iterate over each application, retrieve its properties,
#    and add it to the Dock using dockutil.
# 4. Restart the Dock to apply changes.
#
# Note: Ensure that dockutil is installed and available in
#       your PATH before running this function.
# ============================================================
add_to_macos_dock() {

    # 1. Define an associative array to store application properties
    typeset -A applications

    # 2. Retrieve the list of applications from the YAML file
    applications_list=$(yq eval '.applications | keys | .[]' "$YAML_FILE")

    # 3. Iterate over each application, retrieve its properties, and add it to the Dock
    for app in ${(f)applications_list}; do
        app=$(echo $app | tr -d '"')
        
        name=$(yq eval ".applications[\"$app\"].name" "$YAML_FILE")
        type=$(yq eval ".applications[\"$app\"].type" "$YAML_FILE")
        directory=$(yq eval ".applications[\"$app\"].directory" "$YAML_FILE")
        directory=$(expand_vars "$directory")

        if [ "$directory" != "not specified" ]; then
            dockutil --add "$directory"
            log_message "($name) $directory has been added to the Dock."
        fi
    done

    # 4. Restart the Dock to apply changes
    killall Dock

    log_message "Software packages installed..."    
}


# ============================================================
# Function: init_files
# Description: Initializes files specified in a YAML file by
# copying them from a source to a destination with specified
# permissions. The function logs each step of the process.
#
# Steps:
# 1. Log the initialization message.
# 2. Retrieve the number of entries in the init_list from the YAML file.
# 3. Iterate over each entry in the init_list.
# 4. For each entry:
#    a. Retrieve the name, source, destination, and permissions.
#    b. Expand any environment variables in the source, destination, and permissions.
#    c. Log the details of the current entry.
#    d. Copy the file or directory from the source to the destination with the specified permissions.
#    e. Log the success or failure of the copy operation.
#
# Note: Ensure that the YAML file is correctly formatted and
#       that the yq command-line tool is installed and available
#       in your PATH.
# ============================================================
init_files() {
    # 1. Log the initialization message
    log_message "Initializing files specified in $YAML_FILE..."

    # 2. Retrieve the number of entries in the init_list from the YAML file
    num_entries=$(yq eval '.init_list | length' "$YAML_FILE")

    # 3. Iterate over each entry in the init_list
    for i in $(seq 0 $(($num_entries - 1))); do
        # 4. For each entry:
        name=$(yq eval ".init_list[$i].name" "$YAML_FILE")

        log_message "Name: $name"
        log_message "  Items:"

        # 4a. Retrieve the source, destination, and permissions
        source=$(yq eval ".init_list[$i].source" "$YAML_FILE")
        destination=$(yq eval ".init_list[$i].destination" "$YAML_FILE")
        permissions=$(yq eval ".init_list[$i].permissions" "$YAML_FILE")
        # 4b. Expand any environment variables in the source, destination, and permissions
        source=$(expand_vars "$source")
        destination=$(expand_vars "$destination")
        permissions=$(expand_vars "$permissions")
        # 4c. Log the details of the current entry
        log_message "    Source: $source"
        log_message "    Destination: $destination"
        log_message "    Permissions: $permissions"
        log_message "Copying $source to $destination..."
        # 4d. Copy the file or directory from the source to the destination with the specified permissions
        copy_file_or_dir "$source" "$destination" "$permissions"

        # 4e. Log the success or failure of the copy operation
        if [ $? -eq 0 ]; then
            log_message "Copied $source to $destination successfully."
        else
            log_message "Failed to copy $source to $destination." 1
        fi

        log_message ""
    done
}

# ============================================================
# Function: copy_file_or_dir
# Description: Copies a file or directory from a source path to
# a destination path. If the source is a directory, it copies
# the entire directory recursively and sets the specified permissions.
#
# Parameters:
# - $1: The source path of the file or directory to copy.
# - $2: The destination path where the file or directory should
#       be copied.
# - $3: The permissions to set on the copied file or directory.
#
# Steps:
# 1. Retrieve the source, destination, and permissions from the arguments.
# 2. Check if the destination directory exists.
#    - If it does not exist, create the destination directory.
# 3. Check if the source path is a directory.
#    - If it is a directory, copy it recursively to the destination
#      and set the permissions recursively.
#    - If it is a file, copy the file to the destination and set
#      the permissions.
# 4. Log a success message indicating the file or directory has
#    been copied and permissions have been set.
#
# Globals:
# - None
#
# Note: Ensure that the source, destination, and permissions are
#       provided as arguments when calling this function.
# ============================================================
copy_file_or_dir() {

    # 1. Retrieve the source, destination, and permissions from the arguments
    local source="$1"
    local destination="$2"
    local permissions="$3"

    # 2. Check if the destination directory exists
    if [ ! -d "$(dirname "$destination")" ]; then
        log_message "Creating directory $(dirname "$destination")..."
        # If it does not exist, create the destination directory
        mkdir -p "$(dirname "$destination")"
    fi

    # 3. Check if the source path is a directory
    if [ -d "$source" ]; then
        log_message "Copying directory $source to $destination and setting permissions to $permissions..."
        # If it is a directory, copy it recursively to the destination and set the permissions recursively
        cp -r "$source" "$destination"
        chmod -R "$permissions" "$destination"
        # 4. Log a success message indicating the directory has been copied and permissions have been set
        log_message "Copied directory $source to $destination and set permissions recursively to $permissions"
    elif [ -f "$source" ]; then
        log_message "Copying file $source to $destination and setting permissions to $permissions..."
        # If it is a file, copy the file to the destination and set the permissions
        cp "$source" "$destination"
        chmod "$permissions" "$destination"
        # 4. Log a success message indicating the file has been copied and permissions have been set
        log_message "Copied file $source to $destination and set permissions to $permissions"
    else
        log_message "Source $source is neither a file nor a directory. Skipping." 1
    fi
}

# ============================================================
# Function: set_file_permissions
# Description: Sets the specified permissions on a given file
# or directory. If the target is a directory, the permissions
# are applied recursively to all files and subdirectories.
#
# Parameters:
# - $1: The path of the file or directory to set permissions on.
# - $2: The permissions to set (e.g., 755, 644).
#
# Steps:
# 1. Retrieve the target path and permissions from the arguments.
# 2. Check if the target path exists.
#    - If it does not exist, log an error message and exit the function.
# 3. Check if the target path is a directory.
#    - If it is a directory, set the permissions recursively.
#    - If it is a file, set the permissions on the file.
# 4. Log a success message indicating the permissions have been set.
#
# Globals:
# - None
#
# Note: Ensure that the target path and permissions are provided
#       as arguments when calling this function.
# ============================================================
# set_file_permissions() {

#     # Iterate over the associative array and process each item
#     for key in ${(k)files}; do
#         log_message "IS THIS FUNCTION EVEN CALLED?"
#         # Split the values for the current key
#         IFS=' ' read -r dest_file chmod_value <<< "${files[$key]}"

#         # Call the function with the extracted values
#         check_and_fix_permissions "$dest_file" "$chmod_value"
#         # Check if the destination file is a plist launchagent and needs to be loaded with launchctl
#         load_plist_if_needed "$dest_file"
#     done
# }


# Function to check and set permissions
# check_and_fix_permissions() {
#     local INPUT_FILE="$1"
#     local DESIRED_PERMISSIONS="$2"

#     # Check if any arguments were passed
#     if [[ $# -lt 2 ]]; then
#         echo "Usage: $0 <file_or_directory> <permissions>"
#         exit 1
#     fi


#     # Check if the input exists
#     if [[ ! -e "$INPUT_FILE" ]]; then
#         log_message "File or directory '$INPUT_FILE' does not exist. Please check the path and try again."
#         exit 1
#     fi

# # Determine if INPUT_FILE is a file or directory
#     if [[ -d "$INPUT_FILE" ]]; then
#         # It's a directory
#         local CURRENT_PERMISSIONS=$(stat -f "%Lp" "$INPUT_FILE")

#         # Check if the current permissions match desired permissions
#         if [[ "$CURRENT_PERMISSIONS" == "$DESIRED_PERMISSIONS" ]]; then
#             log_message "Permissions for directory '$INPUT_FILE' are already set to $DESIRED_PERMISSIONS."
#         else
#             log_message "Current permissions for directory '$INPUT_FILE' are $CURRENT_PERMISSIONS. Changing to $DESIRED_PERMISSIONS..."

#             # Change the permissions of the directory
#             chmod "$DESIRED_PERMISSIONS" "$INPUT_FILE"

#             # Verify the change
#             local NEW_PERMISSIONS=$(stat -f "%Lp" "$INPUT_FILE")
#             if [[ "$NEW_PERMISSIONS" == "$DESIRED_PERMISSIONS" ]]; then
#                 log_message "Permissions for directory '$INPUT_FILE' successfully changed to $DESIRED_PERMISSIONS."
#             else
#                 log_message "Failed to change permissions for directory '$INPUT_FILE'. Please check manually."
#             fi
#         fi
#     elif [[ -f "$INPUT_FILE" ]]; then
#         # It's a file
#         local CURRENT_PERMISSIONS=$(stat -f "%Lp" "$INPUT_FILE")

#         # Check if the current permissions match desired permissions
#         if [[ "$CURRENT_PERMISSIONS" == "$DESIRED_PERMISSIONS" ]]; then
#             log_message "Permissions for file '$INPUT_FILE' are already set to $DESIRED_PERMISSIONS."
#         else
#             log_message "Current permissions for file '$INPUT_FILE' are $CURRENT_PERMISSIONS. Changing to $DESIRED_PERMISSIONS..."

#             # Change the permissions of the file
#             chmod "$DESIRED_PERMISSIONS" "$INPUT_FILE"

#             # Verify the change
#             local NEW_PERMISSIONS=$(stat -f "%Lp" "$INPUT_FILE")
#             if [[ "$NEW_PERMISSIONS" == "$DESIRED_PERMISSIONS" ]]; then
#                 log_message "Permissions for file '$INPUT_FILE' successfully changed to $DESIRED_PERMISSIONS."
#             else
#                 log_message "Failed to change permissions for file '$INPUT_FILE'. Please check manually."
#             fi
#         fi
#     else
#         log_message "'$INPUT_FILE' is neither a file nor a directory. Please check the path and try again."
#         exit 1
#     fi
# }

# Function to handle plist files with launchctl
# load_plist_if_needed() {
#     local file="$1"
    
#     if [[ "$file" == *.plist ]]; then
#         log_message "Loading plist file '$file' with launchctl..."

#         launchctl unload -w "$file" && launchctl load -w "$file"
#         if [[ $? -eq 0 ]]; then
#             log_message "Successfully loaded '$file'."
#         else
#             log_message "Failed to load '$file'. Please check manually."
#         fi
#     fi
# }

# Function to create a marker file for a function
create_marker_file() {
    local marker_file="$1"
    local current_date=$(date '+%Y-%m-%d')
    local last_update_date=""

    if [ -f "$marker_file" ]; then
        last_update_date=$(cat "$marker_file")
    else
        last_update_date=""
    fi

    # Create the marker file if the date has changed
    if [ "$current_date" != "$last_update_date" ]; then
        log_message "Creating $marker_file ..."
        echo "$current_date" > "$marker_file"
    elif [ "$current_date" = "$last_update_date" ]; then
        log_message "The $marker_file timestamp is $last_update_date"
    else
        log_message "Undefined error in function 'create_marker_file()'" 1
    fi
}

download_files() {
    log_message "Downloading additional files specified in $YAML_FILE..."
    # Define an associative array to store the package names and their properties
    # Defined inside the function because 'yk' is not available until homebrew is installed
    typeset -A downloads

    # Retrieve the file names from the YAML file using yq
    downloads_list=$(yq eval '.downloads | keys | .[]' "$YAML_FILE")

    # Regular expression for a valid URL
    url_regex="^(https?|ftp|file)://[-A-Za-z0-9+&@#/%?=~_|!:,.;]*[-A-Za-z0-9+&@#/%=~_|]$"

    # Iterate over each file name
    for download in ${(f)downloads_list}; do
        # Remove quotes from the file name
        download=$(echo $download | tr -d '"')
        
        # Retrieve the appname, type, and path for the current file
        name=$(yq eval ".downloads[\"$download\"].name" "$YAML_FILE")
        source=$(yq eval ".downloads[\"$download\"].source" "$YAML_FILE")
        destination=$(yq eval ".downloads[\"$download\"].destination" "$YAML_FILE")
        # Expand environment variables in retrieved values and remove leading/trailing whitespace
        name=$(expand_vars "$name" | xargs)
        source=$(expand_vars "$source" | xargs)
        destination=$(expand_vars "$destination" | xargs)

        # Get the parent directory of the destination file
        parent_dir=$(dirname "$destination")

        if [ ! -d "$parent_dir" ]; then
            log_message "Creating directory $parent_dir..."
            mkdir -p "$parent_dir"
        fi

        #Checks if the URL is valid,  and the destination directory exists
        if echo "$source" | grep -qE "$url_regex" && [ -d "$parent_dir" ] && [ -w "$parent_dir" ]; then
            log_message "URL is valid..."
            log_message "Downloading $source to $parent_dir"

            curl -L -o "$destination" "$source"
            
            if [ -f "$destination" ]; then
                log_message "File successfully downloaded to $destination ..."
            else
                log_message "Failed to download file..." 1
            fi
        else
            log_message "Failed to download: $source . Invalid source or parent directory is not writable." 1
        fi
    done

    log_message "All additional files downloaded..."    
}

cleanup() {

    directories=(
        $HOME/init
    )

    files=(
        $HOME/config.yaml
        $HOME/terminal_session.log
        $HOME/init.log
        $HOME/bootstrap.sh
        $HOME/.init_template_marker_file_ran
        $HOME/.install_homebrew_ran
        $HOME/.install_homebrew_ran
    )

    for dir in $directories; do
    
        if [ -d "$dir" ]; then
            log_message "Directory $HOME/init exists..."
            log_message "Deleting $HOME/init ..."
            rm -R "$HOME/init"
        fi

    done

    for file in $files; do
    
        if [ -f "$file" ]; then
            log_message "File $file exists..."
            log_message "Deleting $file ..."
            rm -f "$file"
        fi

    done

}

# ============================================
# Main Execution
# ============================================

# Handle help and version options
if [[ "$1" == "-h" || "$1" == "--help" ]]; then
    show_help
    exit 0
    elif [[ "$1" == "-v" || "$1" == "--version" ]]; then
    show_version
    exit 0
    else
    show_welcome
fi

{
# Reset log to empty
reset_logfile

# Install Xcode command-line tools (because Homebrew requires them! (git))
#install_xcode_command_line_utils


# Installs Homebrew without sudo rights in $HOME/homebrew
install_homebrew

# Clone the init repo that contains the rest of the scripts that will setup and configure user specific stuff
clone_init_repo

# Copies files from the clone_init_repo folder to specific folders, e.g. Library/LaunchAgents
init_files


# Declares variables that are using 'yq' to read from the YAML file
# (yk isn't available until after Homebrew is installed)
#declare_variables

# Installs all software using Homebrew
install_software

# Creates the .zshenv file:
#   XDG_CONFIG_HOME = Define the base directory for user-specific configuration files
#   ZDOTDIR = specifies where Zsh configuration files are located
#   GIT_CONFIG_GLOBAL = location of the .gitconfig file
configure_zsh


# Installs Nextcloud without sudo/admin rights
install_nextcloud

# Change wallpaper
osascript -e 'tell application "System Events" to set picture of every desktop to "'"$HOME/Pictures/wallpaper_test.png"'"'

# Adds GUI apps that are installed to /Applications to the macOS Dock! (magic)
add_to_macos_dock


# Configure software
configure_software

# Set file permissions
#set_file_permissions

# Downloads files specified in the "downloads" array
download_files

# The marker file indicates the date of when the init_template.sh script last ran
log_message "Done!"

create_marker_file "$INIT_TEMPLATE_MARKER_FILE"
} 2>&1 | tee -a "$RECORDING_LOG"

# Quit all open terminals and open iTerm2
log_message "Quitting the old Terminal and opening iTerm2..."

# Open iTerm2
log_message "Opening iTerm2..."
open -a iTerm

log_message "Quitting Terminal..."
killall Terminal 

# Cleaning files and folders
cleanup

exit 0