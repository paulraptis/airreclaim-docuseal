# AirReclaim deployment package

This package keeps the public signing domain non-indexable, redirects its root to AirReclaim, serves the exact corresponding-source archive, and proxies signer/admin paths to the custom image.

## Release sequence

1. Run the upstream test suite and asset build.
2. Commit the release source and run `bash ops/airreclaim/build-release.sh`.
3. Push the image to the approved registry and record its immutable digest.
4. Copy the generated source archive and checksum into `ops/airreclaim/public/source/` on the host.
5. Set `AIRRECLAIM_DOCUSEAL_IMAGE` to the digest-pinned image reference.
6. Create a full backup with `backup-docuseal.sh` and restore-test it on an isolated instance.
7. Test a synthetic invitation, signature, completion, audit trail, webhook, and redirect on staging.
8. During the approved maintenance window, stop the existing app, make a final full backup, start this image, and verify health and a synthetic signer flow.

## Rollback

Stop the custom image, restore the previous digest-pinned image, and restore the pre-release data snapshot if a schema migration is not backward compatible. Do not roll back only the SQLite file while keeping newer signed-file blobs or configuration.

## Signature assurance

The compose file passes through DocuSeal's supported `CERTS`, `TRUSTED_CERTS`, and `TIMESERVER_URL` settings only when they are supplied by the deployment environment. They are configuration hooks only. Leave them unset until an approved document-signing certificate and RFC 3161 timestamp service are available. The standard flow must not be represented as a qualified electronic signature unless a qualified trust service and the corresponding recipient policy are explicitly approved.
