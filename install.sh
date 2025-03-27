#!/bin/bash

# Function to check and install a package
install_package() {
    local package_name="$1"
    local install_cmd="$2"
    local check_cmd="$3"

    if ! eval "$check_cmd"; then
        echo "Installing $package_name..."
        eval "$install_cmd" || { echo "Failed to install $package_name"; exit 1; }
    else
        echo "$package_name is already installed."
    fi
}

printf "\n=== Checking VS Code Installation ===\n"

# Check if VS Code is installed
if ! command -v code > /dev/null 2>&1; then
    read -p "VS Code is not installed. Do you want to add the repo and install it? (y/n): " choice < /dev/tty
    case "$choice" in
        [Yy]*)
            if command -v apt-get > /dev/null 2>&1; then
                echo "Adding Microsoft's GPG key and repository for VS Code..."
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor | sudo tee /usr/share/keyrings/packages.microsoft.gpg > /dev/null
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" | sudo tee /etc/apt/sources.list.d/vscode.list > /dev/null
                sudo apt update
                install_package "Visual Studio Code" "sudo apt install -y code" "dpkg -l | grep -q code"

            elif command -v pacman > /dev/null 2>&1; then
                install_package "Visual Studio Code" "sudo pacman -S --noconfirm code" "pacman -Qi code > /dev/null 2>&1"

            elif command -v dnf > /dev/null 2>&1; then
                sudo rpm --import https://packages.microsoft.com/keys/microsoft.asc
                sudo sh -c 'echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo'
                sudo dnf check-update
                install_package "Visual Studio Code" "sudo dnf install -y code" "dnf list --installed code > /dev/null 2>&1"

            else
                echo "Error: Unsupported package manager. Please install VS Code manually."
                exit 1
            fi
            ;;
        [Nn]*)
            echo "Skipping VS Code installation."
            ;;
        *)
            echo "Invalid input. Skipping VS Code installation."
            ;;
    esac
else
    echo "VS Code is already installed."
fi

printf "\n=== Installing python-nautilus ===\n"

# Install python-nautilus based on package manager
if command -v pacman > /dev/null 2>&1; then
    install_package "python-nautilus" "sudo pacman -S --noconfirm python-nautilus" \
        "pacman -Qi python-nautilus > /dev/null 2>&1"

elif command -v apt-get > /dev/null 2>&1; then
    package_name=$(apt-cache search --names-only '^python3?-nautilus$' | awk '{print $1}' | head -n1)
    [ -z "$package_name" ] && package_name="python3-nautilus"
    install_package "$package_name" "sudo apt-get install -y $package_name" \
        "dpkg -l | grep -q $package_name"

elif command -v dnf > /dev/null 2>&1; then
    install_package "nautilus-python" "sudo dnf install -y nautilus-python" \
        "dnf list --installed nautilus-python > /dev/null 2>&1"

else
    echo "Error: Unsupported package manager. Please install python-nautilus manually."
    exit 1
fi

# Remove old extension files
printf "\n=== Removing previous version (if found) ===\n"
EXT_DIR="$HOME/.local/share/nautilus-python/extensions"
mkdir -p "$EXT_DIR"
rm -f "$EXT_DIR/VSCodeExtension.py" "$EXT_DIR/code-nautilus.py"

# Download and install the latest extension
printf "\n=== Downloading the newest version ===\n"
if wget -q -O "$EXT_DIR/code-nautilus.py" "https://raw.githubusercontent.com/harry-cpp/code-nautilus/master/code-nautilus.py"; then
    echo "Download successful."
else
    echo "Error: Failed to download the extension."
    exit 1
fi

# Restart Nautilus
printf "\n=== Restarting Nautilus ===\n"
if nautilus -q; then
    echo "Nautilus restarted successfully."
else
    echo "Warning: Failed to restart Nautilus. Try restarting manually."
fi

printf "\n=== Installation Complete ===\n"
