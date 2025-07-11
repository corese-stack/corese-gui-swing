#!/bin/bash

# Check if the user provided both the JSON and HTML output filenames as arguments
if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: $0 <json_output_file> <html_output_file>"
    exit 1
fi

# Get the output file names from the arguments
json_output_file="$1"
html_output_file="$2"

# Set minimal version (before which no documentation would be generated in a compatible way)
minimal_version="4.6.0"

# Get all Git tags and filter by the form vX.Y.Z (semantic versioning)
tags=$(git tag --sort=-v:refname | grep -E '^v[0-9]+\.[0-9]+\.[0-9]+$')

# Initialize an empty array to hold JSON objects
json_array=()

# Initialize the HTML content
html_content="<html>
<head>
  <meta http-equiv=\"refresh\" content=\"0; url=https://corese-stack.github.io/corese-gui-swing/{{ latest_version }}/\">
  <title>Documentation Versions</title>
</head>
<body>
  <h1>Documentation Versions</h1>
  <ul>"

# Function to compare versions to minimal version
version_greater_equal() {
    # Use sort -V for natural version comparison
    test "$(echo -e "$1\n$2" | sort -V | head -n 1)" = "$2"
}

# Initialize the first flag to identify the latest tag
is_first=true
latest_version=""

# Loop through each tag
for tag in $tags; do
    version=${tag#v}

    # Check if the version is greater than or equal to the minimal version
    if version_greater_equal "$version" "$minimal_version"; then
        # Determine if this is the latest version
        if $is_first; then
            preferred="true"
            name="$tag (latest)"
            latest_version="$tag"
            is_first=false
        else
            preferred="false"
            name="$tag (stable)"
        fi

        # Create a JSON object for the tag
        json_object=$(cat <<EOF
{
    "name": "$name",
    "version": "stable",
    "url": "https://corese-stack.github.io/corese-gui-swing/$tag/",
    "preferred": $preferred
}
EOF
        )

        # Add the JSON object to the array
        json_array+=("$json_object")

        # Add HTML list item
        html_content="$html_content
    <li><a href=\"https://corese-stack.github.io/corese-gui-swing/$tag/\">$name</a></li>"
    fi
done

# Close the HTML content
html_content="$html_content
  </ul>
  <p>If you are not redirected, click <a href=\"https://corese-stack.github.io/corese-gui-swing/$latest_version/\">here</a>.</p>
</body>
</html>"

# Combine JSON objects into array format
json_output=$(printf ",\n%s" "${json_array[@]}")
echo -e "[\n${json_output:2}\n]" > "$json_output_file"

# Finalize and write HTML file
html_content="${html_content//\{\{ latest_version \}\}/$latest_version}"
echo "$html_content" > "$html_output_file"

# Print confirmation
echo "JSON data has been written to $json_output_file"
echo "HTML landing page has been written to $html_output_file"
