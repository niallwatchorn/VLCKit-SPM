#!/bin/sh

set -eu

ROOT_DIR="$(CDPATH= cd -- "$(dirname "$0")" && pwd)"
WORK_DIR="$ROOT_DIR/.tmp"
ARTIFACTS_DIR="$ROOT_DIR/Artifacts"
PACKAGE_FILE="$ROOT_DIR/Package.swift"
LICENSE_FILE="$ROOT_DIR/LICENSE"
INDEX_URL="https://download.videolan.org/cocoapods/unstable/"

UPSTREAM_VERSION="4.0.0a19"
RELEASE_TAG=""
REPO_URL=""
SOURCE_URL=""
SOURCE_PATH=""
KEEP_TEMP=0

usage() {
  cat <<EOF
Usage: ./generate.sh [options]

Options:
  --version <vlckit-version>     Upstream VLCKit version, e.g. 4.0.0a19
  --release-tag <tag>            Semver tag for this package repo, e.g. 4.0.0-alpha.19
  --repo-url <url>               GitHub repo URL used in Package.swift release URL
  --source-url <url>             Exact archive/artifact URL; skips index discovery
  --source-path <path>           Local archive or VLCKit.xcframework path
  --keep-temp                    Keep extracted temporary files
  --help                         Show this help

Examples:
  ./generate.sh --version 4.0.0a19 --repo-url https://github.com/niallwatchorn/VLCKit-SPM
  ./generate.sh --version 4.0.0a19 --release-tag 4.0.0-alpha.19 --repo-url https://github.com/niallwatchorn/VLCKit-SPM
  ./generate.sh --version 4.0.0a19 --repo-url https://github.com/niallwatchorn/VLCKit-SPM --source-url https://code.videolan.org/.../download?file_type=archive
  ./generate.sh --version 4.0.0a19 --repo-url https://github.com/niallwatchorn/VLCKit-SPM --source-path /Users/niall/Downloads/VLCKit-binary/VLCKit.xcframework
EOF
}

semver_tag_from_version() {
  version="$1"

  if printf '%s' "$version" | grep -Eq '^[0-9]+\.[0-9]+\.[0-9]+a[0-9]+$'; then
    base="${version%a*}"
    alpha="${version##*a}"
    printf '%s-alpha.%s\n' "$base" "$alpha"
    return 0
  fi

  printf '%s\n' "$version"
}

replace_manifest_value() {
  key="$1"
  value="$2"
  escaped_value=$(printf '%s' "$value" | sed 's/[\/&]/\\&/g')
  sed -i '' "s/^let $key = \".*\"$/let $key = \"$escaped_value\"/" "$PACKAGE_FILE"
}

resolve_source_url() {
  version="$1"
  index_html="$WORK_DIR/index.html"

  curl -fLsS "$INDEX_URL" -o "$index_html"

  archive_name=$(
    grep -Eo "VLCKit-${version}-[A-Za-z0-9.-]+\\.tar\\.xz" "$index_html" \
      | head -n 1
  )

  if [ -z "${archive_name:-}" ]; then
    echo "Could not find a VLCKit archive for version $version at $INDEX_URL" >&2
    exit 1
  fi

  printf '%s%s\n' "$INDEX_URL" "$archive_name"
}

extract_archive() {
  archive_path="$1"
  destination_dir="$2"

  case "$archive_path" in
    *.tar.xz|*.txz)
      tar -xf "$archive_path" -C "$destination_dir"
      ;;
    *.tar.gz|*.tgz)
      tar -xzf "$archive_path" -C "$destination_dir"
      ;;
    *.tar.bz2|*.tbz2)
      tar -xjf "$archive_path" -C "$destination_dir"
      ;;
    *.tar)
      tar -xf "$archive_path" -C "$destination_dir"
      ;;
    *.zip)
      ditto -x -k "$archive_path" "$destination_dir"
      ;;
    *)
      echo "Unsupported archive type for $archive_path" >&2
      echo "Pass a .zip, .tar, .tar.gz, .tar.bz2 or .tar.xz archive URL." >&2
      exit 1
      ;;
  esac
}

copy_local_source() {
  source_path="$1"
  destination_dir="$2"

  if [ ! -e "$source_path" ]; then
    echo "Local source path does not exist: $source_path" >&2
    exit 1
  fi

  case "$source_path" in
    *.xcframework)
      ditto "$source_path" "$destination_dir/$(basename "$source_path")"
      ;;
    *)
      destination_file="$destination_dir/$(basename "$source_path")"
      cp "$source_path" "$destination_file"
      extract_archive "$destination_file" "$destination_dir"
      ;;
  esac
}

while [ "$#" -gt 0 ]; do
  case "$1" in
    --version)
      UPSTREAM_VERSION="$2"
      shift 2
      ;;
    --release-tag)
      RELEASE_TAG="$2"
      shift 2
      ;;
    --repo-url)
      REPO_URL="$2"
      shift 2
      ;;
    --source-url)
      SOURCE_URL="$2"
      shift 2
      ;;
    --source-path)
      SOURCE_PATH="$2"
      shift 2
      ;;
    --keep-temp)
      KEEP_TEMP=1
      shift 1
      ;;
    --help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [ -z "$RELEASE_TAG" ]; then
  RELEASE_TAG="$(semver_tag_from_version "$UPSTREAM_VERSION")"
fi

if [ -z "$REPO_URL" ]; then
  echo "--repo-url is required so Package.swift points to your release asset." >&2
  exit 1
fi

if [ -n "$SOURCE_URL" ] && [ -n "$SOURCE_PATH" ]; then
  echo "Use either --source-url or --source-path, not both." >&2
  exit 1
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR" "$ARTIFACTS_DIR"

if [ -z "$SOURCE_URL" ] && [ -z "$SOURCE_PATH" ]; then
  SOURCE_URL="$(resolve_source_url "$UPSTREAM_VERSION")"
fi

ARCHIVE_PATH="$WORK_DIR/VLCKit.tar.xz"
ZIP_PATH="$ARTIFACTS_DIR/VLCKit.xcframework.zip"

if [ -n "$SOURCE_PATH" ]; then
  echo "Using local source at $SOURCE_PATH"
  copy_local_source "$SOURCE_PATH" "$WORK_DIR"
else
  case "$SOURCE_URL" in
    *.zip)
      ARCHIVE_PATH="$WORK_DIR/VLCKit.zip"
      ;;
    *.tar.gz|*.tgz)
      ARCHIVE_PATH="$WORK_DIR/VLCKit.tar.gz"
      ;;
    *.tar.bz2|*.tbz2)
      ARCHIVE_PATH="$WORK_DIR/VLCKit.tar.bz2"
      ;;
    *.tar)
      ARCHIVE_PATH="$WORK_DIR/VLCKit.tar"
      ;;
  esac

  echo "Downloading $SOURCE_URL"
  curl -fL "$SOURCE_URL" -o "$ARCHIVE_PATH"

  echo "Extracting archive"
  extract_archive "$ARCHIVE_PATH" "$WORK_DIR"
fi

XCFRAMEWORK_PATH=$(
  find "$WORK_DIR" -type d -name 'VLCKit.xcframework' -print | head -n 1
)

if [ -z "${XCFRAMEWORK_PATH:-}" ]; then
  echo "Could not find VLCKit.xcframework in extracted archive." >&2
  echo "If you downloaded the GitLab 'source code zip', that is not enough by itself." >&2
  echo "Use the built artifact archive that contains VLCKit.xcframework, such as the tag's dev-artifacts download." >&2
  exit 1
fi

echo "Creating $ZIP_PATH"
rm -f "$ZIP_PATH"
ditto -c -k --sequesterRsrc --keepParent "$XCFRAMEWORK_PATH" "$ZIP_PATH"

echo "Computing SwiftPM checksum"
CHECKSUM="$(swift package compute-checksum "$ZIP_PATH")"
RELEASE_BASE_URL="${REPO_URL%/}/releases/download"

replace_manifest_value "vlcUpstreamVersion" "$UPSTREAM_VERSION"
replace_manifest_value "vlcReleaseTag" "$RELEASE_TAG"
replace_manifest_value "vlcReleaseBaseURL" "$RELEASE_BASE_URL"
replace_manifest_value "vlcChecksum" "$CHECKSUM"

COPYING_PATH=$(
  find "$WORK_DIR" -type f \( -name 'COPYING.txt' -o -name 'COPYING' \) -print | head -n 1
)

if [ -n "${COPYING_PATH:-}" ]; then
  cp "$COPYING_PATH" "$LICENSE_FILE"
fi

if [ "$KEEP_TEMP" -ne 1 ]; then
  rm -rf "$WORK_DIR"
fi

cat <<EOF

Done.

Upstream VLCKit version: $UPSTREAM_VERSION
Package release tag:    $RELEASE_TAG
Binary zip:             $ZIP_PATH
Checksum:               $CHECKSUM

Next steps:
1. Commit the updated Package.swift, README.md, LICENSE and generate.sh.
2. Push your repo to GitHub.
3. Create a GitHub release for tag $RELEASE_TAG.
4. Upload Artifacts/VLCKit.xcframework.zip to that release.
5. Point your apps at this package repo and tag.
EOF
