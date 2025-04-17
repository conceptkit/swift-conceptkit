#!/bin/bash

total=0

for file in $(find ./Sources -type f -name '*.swift'); do
  count=$(awk '
    /^[[:space:]]*$/ { next }
    /^[[:space:]]*\/\/.*$/ { next }
    { count++ }
    END { print count }
  ' "$file")
  echo "$count	$file"
  ((total += count))
done

echo "Total Count: $total"
