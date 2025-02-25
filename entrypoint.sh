#!/bin/sh -l
# shellcheck disable=SC2039

git config --global --add safe.directory /github/workspace

# For Docker Image CI test job
if [ "$REPO" = "rIeLaPse/generate-changelog-action" ]; then
  git clone --quiet https://github.com/"$REPO"
  cd generate-changelog-action || exit
fi

if [ -z "$PACKAGE_DIR" ]; then
  echo "No path for the package.json passed. Fallbacking to root directory."
else
  echo "package-dir detected. Using its value."
  cp "$PACKAGE_DIR" package.json
fi

if [ -z "$FROM_TAG" ]; then
  echo "No from-tag passed. Fallbacking to git previous tag."
  previous_tag=$(git tag --sort version:refname | tail -n 2 | head -n 1)
else
  echo "From-tag detected. Using its value."
  previous_tag=$FROM_TAG
fi

if [ -z "$TO_TAG" ]; then
  echo "No to-tag passed. Fallbacking to git previous tag."
  new_tag=$(git tag --sort version:refname | tail -n 1)
else
  echo "To-tag detected. Using its value."
  new_tag=$TO_TAG
fi

if [ -z "$TYPE" ]; then
  echo "No type passed. Fallbacking to unset."
else
  echo "Type detected. Using its value."
  case $TYPE in
    patch)
     changelog_type="--patch"
     ;;
    minor)
     changelog_type="--minor"
     ;;
    major)
     changelog_type="--major"
     ;;
  esac
fi

if [ -z "$EXCLUDE" ]; then
  echo "No commit types selected to exclude. Fallbacking to unset."
else
  echo "Commit types selected to exclude. Using its value."
  exclude_types="--exclude $EXCLUDE"
fi

if [ -z "$ALLOW_UNKNOWN" ]; then
  echo "Unknown commit types not allowed."
else
  echo "Allowing unknown commit types."
  unknown_commits="--allow-unknown "
fi


if [ -z "$CREATE_PACKAGE_JSON" ]; then
  echo "Use existing package.json"
else
  echo "Create package.json on the fly"
  touch package.json
  echo "{}" > package.json
fi


# shellcheck disable=SC2086
changelog=$(generate-changelog "$changelog_type" -t "$previous_tag..$new_tag" ${exclude_types} "$unknown_commits" --file -)

changelog="${changelog//'%'/'%25'}"
changelog="${changelog//$'\n'/'%0A'}"
changelog="${changelog//$'\r'/'%0D'}"

echo "$changelog"

echo "::set-output name=changelog::$changelog"
