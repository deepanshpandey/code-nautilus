# VSCode Nautilus Extension
#
# Place me in ~/.local/share/nautilus-python/extensions/,
# ensure you have the python-nautilus package, restart Nautilus, and enjoy :)
#
# This script is released to the public domain.

from gi.repository import Nautilus, GObject
import subprocess
import os
import shlex

# Path to VS Code executable
VSCODE = "code"

# Context menu name
VSCODENAME = "Code"

# Always open in a new window?
NEWWINDOW = False


class VSCodeExtension(GObject.GObject, Nautilus.MenuProvider):

    def launch_vscode(self, menu, files):
        paths = []
        args = ["--new-window"] if NEWWINDOW else []

        for file in files:
            location = file.get_location()
            if location is None:
                continue  # Avoid errors if location is None

            filepath = location.get_path()
            paths.append(shlex.quote(filepath))

            # Open in a new window if a directory is selected
            if os.path.isdir(filepath) and os.path.exists(filepath):
                args = ["--new-window"]

        # Construct the final command
        command = [VSCODE] + args + paths
        subprocess.Popen(command, shell=False)

    def get_file_items(self, *args):
        files = args[-1]
        item = Nautilus.MenuItem(
            name="VSCodeOpen",
            label=f"Open in {VSCODENAME}",
            tip="Opens the selected files with VSCode"
        )
        item.connect("activate", self.launch_vscode, files)
        return [item]

    def get_background_items(self, *args):
        file_ = args[-1]
        item = Nautilus.MenuItem(
            name="VSCodeOpenBackground",
            label=f"Open in {VSCODENAME}",
            tip="Opens the current directory in VSCode"
        )
        item.connect("activate", self.launch_vscode, [file_])
        return [item]
