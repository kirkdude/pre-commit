#!/bin/bash

# Add .PHONY declarations for common targets to Makefile.am files
# This fixes the checkmake minphony rule violations

common_targets="all clean test check install uninstall"

find . -name "Makefile.am" -type f | while read -r makefile; do
    echo "Processing: $makefile"

    # Check if the file already has any .PHONY declarations
    if grep -q "^\.PHONY" "$makefile" 2>/dev/null; then
        # Add after existing .PHONY lines
        temp_file=$(mktemp)
        awk -v targets="$common_targets" '
        /^\.PHONY/ {
            print
            if (\!added) {
                print ".PHONY: " targets
                added = 1
            }
            next
        }
        { print }
        END {
            if (\!added) {
                print ".PHONY: " targets
            }
        }' "$makefile" > "$temp_file"
        mv "$temp_file" "$makefile"
    else
        # Add at the beginning
        temp_file=$(mktemp)
        echo ".PHONY: $common_targets" > "$temp_file"
        echo "" >> "$temp_file"
        cat "$makefile" >> "$temp_file"
        mv "$temp_file" "$makefile"
    fi

    echo "  Added .PHONY: $common_targets"
done

echo "Completed adding PHONY targets to all Makefile.am files"
