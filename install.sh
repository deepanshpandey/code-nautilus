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

printf "\n=== Installing python-nautilus ===\n"

# Detect package manager and install python-nautilus
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
