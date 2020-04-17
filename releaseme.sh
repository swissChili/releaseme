#!/bin/bash

# Open .env file if it exists
if [ -f .env ]; then
  source .env
fi

if [ -z ${GITHUB_TOKEN+x} ]; then
  echo "Set the GITHUB_TOKEN environmental variable to your GH API key"
  echo "or add it to your .env as GITHUB_TOKEN='<token>'"
  exit 1
fi

# name of the release. -n --name
releasename=''
# file to upload. -f --file
file=''
repo=''
mimetype='application/zip'

while [[ $# -gt 0 ]]; do
  key=$1

  case "$key" in
    -n|--name)
      releasename="$2"
      shift
      ;;
    -f|--file)
      file="$2"
      shift
      ;;
    -r|--repo)
      repo="$2"
      shift
      ;;
    -m|--mime)
      mimetype="$2"
      shift
      ;;
    -h|--help)
      echo "~ releaseme.sh ~"
      echo "Options:"
      echo "  -n --name: the name of the release"
      echo "  -f --file: the file to upload (optional)"
      echo "  -r --repo: the user/repo on github to release to"
      echo "  -m --mime: mime type of file"
      exit 0
      ;;
  esac

  shift
done

if [ -z "$releasename" ]; then
  echo "No release name set. Pass --name <release name>"
  exit 1
fi

if [ -z "$repo" ]; then
  echo "No Github repo specified. Pass --repo user/repo"
  exit 1
fi

# create release
echo "Creating release $releasename"
curl -i -H "Authorization: token $GITHUB_TOKEN" \
  --data '
  {
    "tag_name": "$releasename",
    "target_commitish": "master",
    "name": "$releasename",
    "body": ""
  }  
' -X POST "https://api.github.com/repos/$repo/releases/"

if [ ! -z "$file" ]; then
  echo "Uploading file $file"
  # upload asset
  curl -i -H "Authorization: token $GITHUB_TOKEN" \
    -H "Content-Type: $mime" \
    --data-binary "@$file" \
    -X POST "https://uploads.github.com/repos/$repo/releases/$releasename/assets?name=$file"
fi
