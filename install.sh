#!/bin/bash

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}  Linux Terminal Gamifier      ${NC}"
echo -e "${BLUE}  Automatic Installer          ${NC}"
echo -e "${BLUE}================================${NC}"

# Define home directory
HOME_DIR="$HOME"
GAMIFIER_FILE="$HOME_DIR/gamifier"
TEMP_FILE="$HOME_DIR/gamifier.tmp"
DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/gamifier"

# Detect shell being used
detect_shell() {
    # Check current shell
    CURRENT_SHELL=$(basename "$SHELL")
    
    # Alternative method of detection if $SHELL is empty
    if [ -z "$CURRENT_SHELL" ]; then
        CURRENT_SHELL=$(ps -p $$ -o comm= | tr -d '-')
    fi
    
    echo "$CURRENT_SHELL"
}

# Download gamifier file
download_gamifier() {
    echo -e "${YELLOW}Downloading the latest version of Linux Terminal Gamifier...${NC}"
    curl --output "$GAMIFIER_FILE" "https://raw.githubusercontent.com/Divinux/linux-terminal-gamifier/refs/heads/main/gamifier"
    
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error downloading the file. Check your internet connection.${NC}"
        exit 1
    fi
    
    # Fix carriage return characters
    tr -d '\r' < "$GAMIFIER_FILE" > "$TEMP_FILE" && mv "$TEMP_FILE" "$GAMIFIER_FILE"
    chmod +x "$GAMIFIER_FILE"
    
    echo -e "${GREEN}File successfully downloaded and fixed.${NC}"
}

# Setup for Bash
setup_bash() {
    echo -e "${YELLOW}Setting up for Bash...${NC}"
    BASHRC="$HOME_DIR/.bashrc"
    
    # Check if configuration already exists in .bashrc
    if grep -q "source ~/gamifier" "$BASHRC"; then
        echo -e "${YELLOW}Existing configuration detected in .bashrc${NC}"
    else
        echo 'source ~/gamifier' >> "$BASHRC"
    fi
    
    # Add PROMPT_COMMAND if it doesn't exist yet
    if ! grep -q "update_exp" "$BASHRC"; then
        echo 'export PROMPT_COMMAND="history -a; history -n; update_exp; $PROMPT_COMMAND"' >> "$BASHRC"
    fi
    
    echo -e "${GREEN}Bash configured successfully!${NC}"
}

# Setup for Zsh
setup_zsh() {
    echo -e "${YELLOW}Setting up for Zsh...${NC}"
    ZSHRC="$HOME_DIR/.zshrc"
    
    # Check if configuration already exists in .zshrc
    if grep -q "source ~/gamifier" "$ZSHRC"; then
        echo -e "${YELLOW}Existing configuration detected in .zshrc${NC}"
    else
        echo 'source ~/gamifier' >> "$ZSHRC"
    fi
    
    # Add precmd and incappendhistory if they don't exist yet
    if ! grep -q "update_exp" "$ZSHRC"; then
        echo -e "setopt incappendhistory\nprecmd() { update_exp; }" >> "$ZSHRC"
    fi
    
    echo -e "${GREEN}Zsh configured successfully!${NC}"
}

# Setup for Fish
setup_fish() {
    echo -e "${YELLOW}Setting up for Fish...${NC}"
    FISH_CONFIG="$HOME_DIR/.config/fish/config.fish"
    
    # Create config.fish directory if it doesn't exist
    mkdir -p "$(dirname "$FISH_CONFIG")"
    
    # Check for bass plugin
    if ! fish -c "functions -q bass" 2>/dev/null; then
        echo -e "${YELLOW}Installing bass plugin for fish...${NC}"
        # Check for fisher
        if ! fish -c "functions -q fisher" 2>/dev/null; then
            echo -e "${YELLOW}Installing fisher (plugin manager for fish)...${NC}"
            curl -sL https://git.io/fisher | source && \
            fish -c "fisher install jorgebucaran/fisher" 2>/dev/null
        fi
        
        # Install bass
        fish -c "fisher install edc/bass" 2>/dev/null
    fi
    
    # Check if configuration already exists in config.fish
    if grep -q "bass source ~/gamifier" "$FISH_CONFIG" 2>/dev/null; then
        echo -e "${YELLOW}Existing configuration detected in config.fish${NC}"
    else
        echo 'bass source ~/gamifier' >> "$FISH_CONFIG"
    fi
    
    # Add hook function if it doesn't exist yet
    if ! grep -q "gamifier_hook" "$FISH_CONFIG" 2>/dev/null; then
        echo -e 'function gamifier_hook --on-event fish_postexec\n    bass "source ~/gamifier && update_exp"\nend' >> "$FISH_CONFIG"
    fi
    
    echo -e "${GREEN}Fish configured successfully!${NC}"
}

# Uninstall from Bash
uninstall_bash() {
    echo -e "${YELLOW}Removing from Bash configuration...${NC}"
    BASHRC="$HOME_DIR/.bashrc"
    
    if [ -f "$BASHRC" ]; then
        # Create a temporary file
        TEMP_BASHRC="${BASHRC}.tmp"
        
        # Remove the source line
        grep -v "source ~/gamifier" "$BASHRC" > "$TEMP_BASHRC"
        
        # Remove the PROMPT_COMMAND line that contains update_exp
        grep -v "update_exp" "$TEMP_BASHRC" > "$BASHRC"
        
        # Remove the temporary file
        rm -f "$TEMP_BASHRC"
        
        echo -e "${GREEN}Removed from Bash configuration.${NC}"
    else
        echo -e "${YELLOW}No .bashrc file found.${NC}"
    fi
}

# Uninstall from Zsh
uninstall_zsh() {
    echo -e "${YELLOW}Removing from Zsh configuration...${NC}"
    ZSHRC="$HOME_DIR/.zshrc"
    
    if [ -f "$ZSHRC" ]; then
        # Create a temporary file
        TEMP_ZSHRC="${ZSHRC}.tmp"
        
        # Remove the source line
        grep -v "source ~/gamifier" "$ZSHRC" > "$TEMP_ZSHRC"
        
        # Remove setopt incappendhistory line
        grep -v "setopt incappendhistory" "$TEMP_ZSHRC" > "$ZSHRC"
        
        # Remove the precmd function
        sed -i '/precmd() { update_exp; }/d' "$ZSHRC" 2>/dev/null || 
        sed '/precmd() { update_exp; }/d' "$ZSHRC" > "$TEMP_ZSHRC" && mv "$TEMP_ZSHRC" "$ZSHRC"
        
        echo -e "${GREEN}Removed from Zsh configuration.${NC}"
    else
        echo -e "${YELLOW}No .zshrc file found.${NC}"
    fi
}

# Uninstall from Fish
uninstall_fish() {
    echo -e "${YELLOW}Removing from Fish configuration...${NC}"
    FISH_CONFIG="$HOME_DIR/.config/fish/config.fish"
    
    if [ -f "$FISH_CONFIG" ]; then
        # Create a temporary file
        TEMP_FISH_CONFIG="${FISH_CONFIG}.tmp"
        
        # Remove the source line
        grep -v "bass source ~/gamifier" "$FISH_CONFIG" > "$TEMP_FISH_CONFIG"
        
        # Remove gamifier_hook function block
        sed '/function gamifier_hook --on-event fish_postexec/,/end/d' "$TEMP_FISH_CONFIG" > "$FISH_CONFIG"
        
        # Remove the temporary file
        rm -f "$TEMP_FISH_CONFIG"
        
        echo -e "${GREEN}Removed from Fish configuration.${NC}"
    else
        echo -e "${YELLOW}No fish config file found.${NC}"
    fi
}

# Uninstall function
uninstall_gamifier() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}  Linux Terminal Gamifier      ${NC}"
    echo -e "${BLUE}  Automatic Uninstaller        ${NC}"
    echo -e "${BLUE}================================${NC}"
    
    # Ask for confirmation
    echo -e "${YELLOW}This will remove Linux Terminal Gamifier and all your progress.${NC}"
    echo -e "${YELLOW}Are you sure you want to continue? (y/n)${NC}"
    read -r response
    
    if [[ ! "$response" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        echo -e "${GREEN}Uninstallation cancelled.${NC}"
        exit 0
    fi
    
    # Determine which shell configuration files to update
    SHELL_TYPE=$(detect_shell)
    echo -e "${YELLOW}Detected shell: ${GREEN}$SHELL_TYPE${NC}"
    
    # Remove configuration from shell config files
    case "$SHELL_TYPE" in
        bash)
            uninstall_bash
            ;;
        zsh)
            uninstall_zsh
            ;;
        fish)
            uninstall_fish
            ;;
        *)
            echo -e "${YELLOW}Shell $SHELL_TYPE not directly supported for automatic uninstallation.${NC}"
            echo -e "${YELLOW}You may need to manually remove gamifier configuration from your shell's config file.${NC}"
            ;;
    esac
    
    # Ask if user wants to keep progress data
    echo -e "${YELLOW}Do you want to keep your progress data for future reinstallation? (y/n)${NC}"
    read -r keep_data
    
    # Remove the gamifier file
    if [ -f "$GAMIFIER_FILE" ]; then
        rm -f "$GAMIFIER_FILE"
        echo -e "${GREEN}Removed gamifier script.${NC}"
    else
        echo -e "${YELLOW}Gamifier script not found.${NC}"
    fi
    
    # Remove the data directory if requested
    if [[ ! "$keep_data" =~ ^([yY][eE][sS]|[yY])$ ]]; then
        if [ -d "$DATA_DIR" ]; then
            rm -rf "$DATA_DIR"
            echo -e "${GREEN}Removed gamifier data directory.${NC}"
        else
            echo -e "${YELLOW}Gamifier data directory not found.${NC}"
        fi
    else
        echo -e "${GREEN}Keeping data in $DATA_DIR for future reinstallation.${NC}"
    fi
    
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}Uninstallation completed!${NC}"
    echo -e "${YELLOW}To apply changes, restart your terminal or run:${NC}"
    echo -e "${BLUE}   source ~/$SHELL_TYPE""rc${NC} (for bash/zsh)"
    echo -e "${BLUE}   source ~/.config/fish/config.fish${NC} (for fish)"
    echo -e "${BLUE}================================${NC}"
    
    exit 0
}

# Main function
main() {
    # Check if the uninstall flag is set
    if [ "$1" = "uninstall" ]; then
        uninstall_gamifier
        exit 0
    fi
    
    # Check if gamifier file exists
    if [ -f "$GAMIFIER_FILE" ]; then
        echo -e "${YELLOW}Gamifier file already exists. Updating...${NC}"
    fi
    
    # Download gamifier file
    download_gamifier
    
    # Detect user's shell
    SHELL_TYPE=$(detect_shell)
    echo -e "${YELLOW}Detected shell: ${GREEN}$SHELL_TYPE${NC}"
    
    # Configure appropriate shell
    case "$SHELL_TYPE" in
        bash)
            setup_bash
            ;;
        zsh)
            setup_zsh
            ;;
        fish)
            setup_fish
            ;;
        *)
            echo -e "${RED}Unsupported shell: $SHELL_TYPE${NC}"
            echo -e "${YELLOW}Please refer to the manual installation instructions in the gamifier file.${NC}"
            exit 1
            ;;
    esac
    
    echo -e "${BLUE}================================${NC}"
    echo -e "${GREEN}Installation completed successfully!${NC}"
    echo -e "${YELLOW}To apply changes, run:${NC}"
    echo -e "${BLUE}   source ~/$SHELL_TYPE""rc${NC} (for bash/zsh)"
    echo -e "${BLUE}   source ~/.config/fish/config.fish${NC} (for fish)"
    echo -e "${YELLOW}Or restart your terminal.${NC}"
    echo -e "${BLUE}================================${NC}"
    echo -e "${YELLOW}Use the following commands:${NC}"
    echo -e "${GREEN}checkrank${NC} - check your current level"
    echo -e "${GREEN}checkstats${NC} - view statistics"
    echo -e "${GREEN}ghelp${NC} - show program information"
    echo -e "${YELLOW}To uninstall, run:${NC}"
    echo -e "${GREEN}./install.sh uninstall${NC}"
    echo -e "${BLUE}================================${NC}"
}

# Run main function with all arguments
main "$@" 