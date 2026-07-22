#!/usr/bin/env bash
set -euo pipefail

data_directory="${DOCUSEAL_DATA_DIRECTORY:?Set DOCUSEAL_DATA_DIRECTORY to the explicit DocuSeal data directory}"
backup_directory="${DOCUSEAL_BACKUP_DIRECTORY:?Set DOCUSEAL_BACKUP_DIRECTORY to an explicit backup directory outside the DocuSeal data directory}"
deployment_directory="${DOCUSEAL_DEPLOYMENT_DIRECTORY:-$(dirname "${data_directory}")}"
database_path="${DOCUSEAL_SQLITE_DATABASE:-${data_directory}/db.sqlite3}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
snapshot_directory="${backup_directory}/docuseal-${timestamp}"

case "${data_directory}:${backup_directory}:${deployment_directory}" in
  *//*|/:*|*::*)
    echo "Unsafe or overlapping backup paths." >&2
    exit 1
    ;;
esac

if [[ "${backup_directory}" == "${data_directory}" || "${backup_directory}" == "${data_directory}/"* ]]; then
  echo "Backup directory must be outside the DocuSeal data directory." >&2
  exit 1
fi

mkdir -p "${snapshot_directory}"
sqlite3 "${database_path}" ".backup '${snapshot_directory}/db.sqlite3'"
tar -C "$(dirname "${data_directory}")" -czf "${snapshot_directory}/docuseal-data.tar.gz" "$(basename "${data_directory}")"

configuration_paths=()
for path in .env docker-compose.yml Caddyfile public caddy caddy-data caddy-config; do
  if [[ -e "${deployment_directory}/${path}" ]]; then
    configuration_paths+=("${path}")
  fi
done
if [[ "${#configuration_paths[@]}" -eq 0 ]]; then
  echo "No deployment configuration or certificate material was found in ${deployment_directory}." >&2
  exit 1
fi
tar -C "${deployment_directory}" -czf "${snapshot_directory}/deployment-config-and-certificates.tar.gz" "${configuration_paths[@]}"

if command -v docker >/dev/null 2>&1; then
  docker image inspect "${DOCUSEAL_CURRENT_IMAGE:-docuseal/docuseal:latest}" > "${snapshot_directory}/docuseal-image-inspect.json"
  docker image inspect "${DOCUSEAL_CURRENT_CADDY_IMAGE:-caddy:latest}" > "${snapshot_directory}/caddy-image-inspect.json"
fi

(
  cd "${snapshot_directory}"
  shasum -a 256 db.sqlite3 docuseal-data.tar.gz deployment-config-and-certificates.tar.gz *-image-inspect.json 2>/dev/null > SHA256SUMS
)

echo "Complete DocuSeal data, configuration, certificate, and image snapshot written to ${snapshot_directory}. Restore-test it on an isolated instance before production deployment."
