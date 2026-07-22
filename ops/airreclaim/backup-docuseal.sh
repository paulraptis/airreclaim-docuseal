#!/usr/bin/env bash
set -euo pipefail

data_directory="${DOCUSEAL_DATA_DIRECTORY:?Set DOCUSEAL_DATA_DIRECTORY to the explicit DocuSeal data directory}"
backup_directory="${DOCUSEAL_BACKUP_DIRECTORY:?Set DOCUSEAL_BACKUP_DIRECTORY to an explicit backup directory outside the DocuSeal data directory}"
database_path="${DOCUSEAL_SQLITE_DATABASE:-${data_directory}/db.sqlite3}"
timestamp="$(date -u +%Y%m%dT%H%M%SZ)"
snapshot_directory="${backup_directory}/docuseal-${timestamp}"

case "${data_directory}" in
  /|"${backup_directory}"|"")
    echo "Unsafe or overlapping backup paths." >&2
    exit 1
    ;;
esac

mkdir -p "${snapshot_directory}"
sqlite3 "${database_path}" ".backup '${snapshot_directory}/db.sqlite3'"
tar -C "$(dirname "${data_directory}")" -czf "${snapshot_directory}/docuseal-data.tar.gz" "$(basename "${data_directory}")"
shasum -a 256 "${snapshot_directory}/db.sqlite3" "${snapshot_directory}/docuseal-data.tar.gz" > "${snapshot_directory}/SHA256SUMS"

echo "Complete DocuSeal snapshot written to ${snapshot_directory}. Restore-test it on an isolated instance before production deployment."
