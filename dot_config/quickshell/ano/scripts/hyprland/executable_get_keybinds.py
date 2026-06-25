#!/usr/bin/env python3
"""
Ano Shell — get_keybinds.py
Parses Hyprland keybind config files and outputs structured JSON
for the cheatsheet module.

Usage: get_keybinds.py --path /path/to/keybinds.conf

Output format:
{
  "children": [
    {
      "name": "Section Name",
      "children": [
        { "keys": "SUPER+T", "action": "exec kitty", "description": "Open terminal" }
      ]
    }
  ]
}
"""

import sys
import json
import re
import argparse

def parse_keybinds(filepath):
    """Parse a Hyprland keybind config file into structured JSON."""
    result = {"children": []}
    current_section = None
    last_comment = ""

    try:
        with open(filepath, 'r') as f:
            lines = f.readlines()
    except FileNotFoundError:
        return result

    for line in lines:
        stripped = line.strip()

        # Skip empty lines
        if not stripped:
            last_comment = ""
            continue

        # Section header: # ═══ Section Name ═══
        if re.match(r'^#\s*[═=]{3,}', stripped):
            continue

        # Section name comment: # Section Name
        if stripped.startswith('#') and not re.match(r'^#\s*[═=]{3,}', stripped):
            comment_text = stripped.lstrip('#').strip()

            # Check if this looks like a section header (follows a divider or is capitalized)
            if comment_text and (comment_text[0].isupper() or comment_text.startswith('(')):
                # Could be section name or description
                if current_section is None or (last_comment == "" and len(comment_text) > 3):
                    # Treat as a new section if it looks like a header
                    if any(c.isupper() for c in comment_text[:3]):
                        current_section = {
                            "name": comment_text,
                            "children": []
                        }
                        result["children"].append(current_section)
                        last_comment = ""
                        continue

            last_comment = comment_text
            continue

        # Keybind line: bind[flags] = MOD, key, dispatcher, params
        bind_match = re.match(r'^bind([elrmntds]*)\s*=\s*(.+)', stripped)
        if bind_match:
            flags = bind_match.group(1)
            parts = [p.strip() for p in bind_match.group(2).split(',', 3)]

            if len(parts) < 3:
                last_comment = ""
                continue

            mod = parts[0]
            key = parts[1]
            dispatcher = parts[2]
            params = parts[3] if len(parts) > 3 else ""

            # Format key combination
            keys = f"{mod}+{key}" if mod else key
            keys = keys.replace("$mainMod", "SUPER").replace("SUPER ", "SUPER+")

            # Format action
            action = f"{dispatcher}"
            if params:
                action += f" {params}"

            # Use comment as description, or format the action
            description = last_comment if last_comment else format_action(dispatcher, params)

            if current_section is None:
                current_section = {"name": "General", "children": []}
                result["children"].append(current_section)

            current_section["children"].append({
                "keys": keys,
                "action": action,
                "description": description
            })

            last_comment = ""
            continue

        last_comment = ""

    # Remove empty sections
    result["children"] = [s for s in result["children"] if s["children"]]

    return result


def format_action(dispatcher, params):
    """Format a dispatcher+params into a human-readable description."""
    descriptions = {
        "exec": f"Run: {params}",
        "workspace": f"Switch to workspace {params}",
        "movetoworkspace": f"Move window to workspace {params}",
        "movetoworkspacesilent": f"Move window silently to workspace {params}",
        "togglefloating": "Toggle floating",
        "fullscreen": "Toggle fullscreen",
        "killactive": "Close active window",
        "movefocus": f"Focus {params}",
        "movewindow": f"Move window {params}",
        "resizeactive": f"Resize {params}",
        "togglesplit": "Toggle split direction",
        "togglegroup": "Toggle group",
        "changegroupactive": f"Switch group window {params}",
        "pin": "Pin window",
        "pseudo": "Toggle pseudo-tiling",
    }

    if dispatcher in descriptions:
        return descriptions[dispatcher]
    return f"{dispatcher} {params}".strip()


def main():
    parser = argparse.ArgumentParser(description='Parse Hyprland keybind config')
    parser.add_argument('--path', required=True, help='Path to keybinds.conf')
    args = parser.parse_args()

    result = parse_keybinds(args.path)
    print(json.dumps(result))


if __name__ == '__main__':
    main()
