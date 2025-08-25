#!/bin/bash

# Add .PHONY declarations specifically for all, clean, test to all Makefile.am files
# This fixes the checkmake minphony rule violations

find . -name "Makefile.am" -type f | while read -r makefile; do
    echo "Processing: $makefile"

    # Check if the file already has .PHONY declarations for all, clean, test
    if grep -q "^\.PHONY.*\ball\b" "$makefile" 2>/dev/null && \
       grep -q "^\.PHONY.*\bclean\b" "$makefile" 2>/dev/null && \
       grep -q "^\.PHONY.*\btest\b" "$makefile" 2>/dev/null; then
        echo "  All required PHONY targets already present"
        continue
    fi

    # Create a simple .PHONY line with the basic required targets
    phony_line=".PHONY: all clean test"

    # Add at the beginning of the file
    temp_file=$(mktemp)
    echo "$phony_line" > "$temp_file"
    echo "" >> "$temp_file"
    cat "$makefile" >> "$temp_file"
    mv "$temp_file" "$makefile"

    echo "  Added $phony_line"
done

echo "Completed adding basic PHONY targets to all Makefile.am files"
