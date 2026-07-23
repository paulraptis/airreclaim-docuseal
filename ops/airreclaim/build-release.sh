#!/usr/bin/env bash
set -euo pipefail

release_version="3.1.2-ar.8"
repository_root="$(git rev-parse --show-toplevel)"
source_only=false

if [[ "${1:-}" == "--source-only" ]]; then
  source_only=true
  shift
fi

release_root="${1:-${repository_root}/release/airreclaim-docuseal-${release_version}}"

if ! git -C "${repository_root}" diff --quiet || ! git -C "${repository_root}" diff --cached --quiet; then
  echo "Refusing to build a release from a dirty checkout." >&2
  exit 1
fi

mkdir -p "${release_root}"

source_archive="${release_root}/airreclaim-docuseal-${release_version}.tar.gz"
git -C "${repository_root}" archive --format=tar.gz --prefix="airreclaim-docuseal-${release_version}/" HEAD > "${source_archive}"
git -C "${repository_root}" rev-parse HEAD > "${release_root}/source-revision.txt"

image_tag="airreclaim/docuseal:${release_version}"
(
  cd "${release_root}"
  shasum -a 256 "$(basename "${source_archive}")" > "$(basename "${source_archive}").sha256"
)

if [[ "${source_only}" == "true" ]]; then
  echo "Built the exact source archive and checksum for ${release_version}."
  exit 0
fi

docker build \
  --label "org.opencontainers.image.title=AirReclaim DocuSeal" \
  --label "org.opencontainers.image.version=${release_version}" \
  --label "org.opencontainers.image.revision=$(git -C "${repository_root}" rev-parse HEAD)" \
  --label "org.opencontainers.image.source=${AIRRECLAIM_DOCUSEAL_SOURCE_REPOSITORY:-https://sign.airreclaim.com/source/airreclaim-docuseal-${release_version}.tar.gz}" \
  --tag "${image_tag}" \
  "${repository_root}"

docker image inspect "${image_tag}" --format '{{json .RepoDigests}}' > "${release_root}/image-repodigests.json"
docker image inspect "${image_tag}" --format '{{.Id}}' > "${release_root}/image-id.txt"

echo "Built ${image_tag}. Publish it, record the registry digest, and set AIRRECLAIM_DOCUSEAL_IMAGE to the digest-pinned reference."
