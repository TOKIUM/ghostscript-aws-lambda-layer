#!/bin/bash
# Publish build/ as a new version of the Lambda layer.
# Run `npm run build` first (`npm run release` does it automatically).
#
# Settings are read from the environment, or from .env.release (copy .env.release.example):
#   EXPECTED_AWS_ACCOUNT_ID  AWS account the layer must be published to (required)
#   AWS_PROFILE              AWS CLI profile to use (optional)
#   AWS_REGION               Region to publish the layer to (default: ap-northeast-1)
set -euo pipefail

LAYER_NAME=ghostscript-aws-lambda-layer
LICENSE_INFO=AGPL-3.0
IMAGE=ghostscript-aws-lambda-layer:latest

cd "$(dirname "$0")/.."

if [ -f .env.release ]; then
  set -a
  # shellcheck source=/dev/null
  . ./.env.release
  set +a
fi

if [ -z "${EXPECTED_AWS_ACCOUNT_ID:-}" ]; then
  echo "EXPECTED_AWS_ACCOUNT_ID is not set. Copy .env.release.example to .env.release and fill it in." >&2
  exit 1
fi

if [ -z "${AWS_PROFILE:-}" ]; then
  unset AWS_PROFILE
fi
export AWS_REGION="${AWS_REGION:-ap-northeast-1}"

if ! account=$(aws sts get-caller-identity --query Account --output text); then
  echo "Failed to get AWS credentials. If you use SSO, run 'aws sso login' and try again." >&2
  exit 1
fi

if [ "$account" != "$EXPECTED_AWS_ACCOUNT_ID" ]; then
  echo "Wrong AWS account: ${account}. The layer must be published to ${EXPECTED_AWS_ACCOUNT_ID}." >&2
  exit 1
fi

# Consumers may read the version from the description, so keep this format.
version=$(docker run --rm --platform linux/amd64 --entrypoint /usr/local/bin/gs "$IMAGE" --version)
description="Ghostscript v${version} (/opt/bin/gs)"

rm -f build/layer.zip
(cd build && zip -q -r layer.zip bin)

echo "Publishing ${LAYER_NAME} (${description}) to account ${account} in ${AWS_REGION}..."

published=$(
  aws lambda publish-layer-version \
    --layer-name "$LAYER_NAME" \
    --description "$description" \
    --license-info "$LICENSE_INFO" \
    --compatible-architectures x86_64 \
    --zip-file fileb://build/layer.zip \
    --query '[Version, LayerVersionArn]' \
    --output text
)
read -r published_version layer_arn <<< "$published"

echo "Published ${layer_arn}"
echo "Published version: ${published_version}"
