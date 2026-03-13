#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "Usage: $0 <json_output_file> <html_output_file>"
    exit 1
fi

json_output_file="$1"
html_output_file="$2"

legacy_docs_base_url="${LEGACY_DOCS_BASE_URL:-https://corese-stack.github.io/corese-gui-swing}"
next_docs_base_url="${NEXT_DOCS_BASE_URL:-https://corese-stack.github.io/corese-gui}"
next_release_api="${NEXT_RELEASE_API:-https://api.github.com/repos/corese-stack/corese-gui/releases}"

legacy_minimal_version="${LEGACY_MINIMAL_VERSION:-4.6.0}"
next_minimal_version="${NEXT_MINIMAL_VERSION:-5.0.0}"
next_dev_tag="${NEXT_DEV_TAG:-dev-prerelease}"

semver_pattern='^v[0-9]+\.[0-9]+\.[0-9]+$'

mkdir -p "$(dirname "$json_output_file")" "$(dirname "$html_output_file")"

version_greater_equal() {
    local current="$1"
    local minimum="$2"
    [[ "$(printf '%s\n%s\n' "$current" "$minimum" | sort -V | head -n 1)" == "$minimum" ]]
}

version_less_than() {
    local current="$1"
    local maximum="$2"
    ! version_greater_equal "$current" "$maximum"
}

legacy_tags=()
next_stable_tags=()
has_next_dev=false

git_tags="$(git tag --sort=-v:refname | grep -E "$semver_pattern" || true)"
for tag in $git_tags; do
    version="${tag#v}"
    if version_greater_equal "$version" "$legacy_minimal_version" && version_less_than "$version" "$next_minimal_version"; then
        legacy_tags+=("$tag")
    fi
done

if command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
    next_release_rows="$(curl -fsSL "$next_release_api" 2>/dev/null | jq -r '.[] | select(.draft == false) | [.tag_name, .published_at] | @tsv' 2>/dev/null || true)"

    declare -A seen_next=()
    while IFS=$'\t' read -r tag _published; do
        [[ -z "${tag:-}" ]] && continue

        if [[ "$tag" == "$next_dev_tag" ]]; then
            has_next_dev=true
            continue
        fi

        if [[ "$tag" =~ $semver_pattern ]]; then
            version="${tag#v}"
            if version_greater_equal "$version" "$next_minimal_version"; then
                if [[ -z "${seen_next[$tag]:-}" ]]; then
                    next_stable_tags+=("$tag")
                    seen_next[$tag]=1
                fi
            fi
        fi
    done <<< "$next_release_rows"
fi

preferred_target=""
if [[ ${#next_stable_tags[@]} -gt 0 ]]; then
    preferred_target="next-stable"
elif [[ "$has_next_dev" == "true" ]]; then
    preferred_target="next-dev"
elif [[ ${#legacy_tags[@]} -gt 0 ]]; then
    preferred_target="legacy"
fi

json_entries=()
html_items=()

add_entry() {
    local name="$1"
    local version="$2"
    local url="$3"
    local preferred="$4"

    json_entries+=("  {
    \"name\": \"$name\",
    \"version\": \"$version\",
    \"url\": \"$url\",
    \"preferred\": $preferred
  }")

    html_items+=("    <li><a href=\"$url\">$name</a></li>")
}

for i in "${!next_stable_tags[@]}"; do
    tag="${next_stable_tags[$i]}"
    if [[ "$i" -eq 0 ]]; then
        name="$tag (latest)"
    else
        name="$tag"
    fi

    preferred="false"
    if [[ "$preferred_target" == "next-stable" && "$i" -eq 0 ]]; then
        preferred="true"
    fi

    add_entry "$name" "$tag" "${next_docs_base_url%/}/$tag/" "$preferred"
done

if [[ "$has_next_dev" == "true" ]]; then
    preferred="false"
    if [[ "$preferred_target" == "next-dev" ]]; then
        preferred="true"
    fi
    add_entry "$next_dev_tag (preview)" "$next_dev_tag" "${next_docs_base_url%/}/$next_dev_tag/" "$preferred"
fi

for i in "${!legacy_tags[@]}"; do
    tag="${legacy_tags[$i]}"
    preferred="false"
    if [[ "$preferred_target" == "legacy" && "$i" -eq 0 ]]; then
        preferred="true"
    fi
    add_entry "$tag (legacy)" "$tag" "${legacy_docs_base_url%/}/$tag/" "$preferred"
done

{
    printf '[\n'
    for i in "${!json_entries[@]}"; do
        printf '%s' "${json_entries[$i]}"
        if (( i < ${#json_entries[@]} - 1 )); then
            printf ',\n'
        else
            printf '\n'
        fi
    done
    printf ']\n'
} > "$json_output_file"

if [[ ${#json_entries[@]} -eq 0 ]]; then
    landing_target_url="${legacy_docs_base_url%/}/main/"
else
    case "$preferred_target" in
        next-stable)
            landing_target_url="${next_docs_base_url%/}/${next_stable_tags[0]}/"
            ;;
        next-dev)
            landing_target_url="${next_docs_base_url%/}/$next_dev_tag/"
            ;;
        legacy)
            landing_target_url="${legacy_docs_base_url%/}/${legacy_tags[0]}/"
            ;;
        *)
            landing_target_url="${legacy_docs_base_url%/}/main/"
            ;;
    esac
fi

{
    cat <<EOT
<html>
<head>
  <meta http-equiv="refresh" content="0; url=${landing_target_url}">
  <title>Corese-GUI Documentation Versions</title>
</head>
<body>
  <h1>Corese-GUI Documentation Versions</h1>
  <p>This documentation site hosts the legacy Swing 4.x line. New 5.x versions are published in the new repository.</p>
  <ul>
EOT
    if [[ ${#html_items[@]} -gt 0 ]]; then
        printf '%s\n' "${html_items[@]}"
    else
        echo "    <li>No version found.</li>"
    fi
    cat <<EOT
  </ul>
  <p>If you are not redirected, click <a href="${landing_target_url}">here</a>.</p>
</body>
</html>
EOT
} > "$html_output_file"

echo "JSON data has been written to $json_output_file"
echo "HTML landing page has been written to $html_output_file"
