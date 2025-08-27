#!/bin/bash

# Add .PHONY declarations for common targets to Makefile.am files
# This fixes the checkmake minphony rule violations

# Common targets that should be marked as phony
required_targets="all clean test"

find . -name "Makefile.am" -type f -print0 | while IFS= read -r -d '' makefile; do
    echo "Processing: $makefile"

    # Check if the file already has .PHONY declarations for all required targets
    all_present=true
    for target in $required_targets; do
        if ! grep -q "^\.PHONY.*\b$target\b" "$makefile" 2>/dev/null; then
            all_present=false
            break
        fi
    done

    if [ "$all_present" = true ]; then
        echo "  All required PHONY targets already present"
        continue
    fi

    # Check if any .PHONY declarations already exist
    if grep -q "^\.PHONY" "$makefile" 2>/dev/null; then
        echo "  File already has some .PHONY declarations, skipping to avoid conflicts"
        echo "  Please manually review and consolidate .PHONY targets in: $makefile"
        continue
    fi

    # Create a simple .PHONY line with the basic required targets
    phony_line=".PHONY: $required_targets"

    # Add at the beginning of the file
    if ! temp_file=$(mktemp); then
        echo "  Error: Failed to create temporary file"
        continue
    fi

    echo "$phony_line" > "$temp_file"
    echo "" >> "$temp_file"

    if cat "$makefile" >> "$temp_file"; then
        mv "$temp_file" "$makefile"
        echo "  Added $phony_line"
    else
        echo "  Error: Failed to process $makefile"
        rm -f "$temp_file"
    fi
done

echo "Completed processing Makefile.am files for PHONY targets"
