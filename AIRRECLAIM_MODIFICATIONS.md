# AirReclaim DocuSeal modifications

Release: `3.1.2-ar.5`

This repository is based on DocuSeal `3.1.2` at commit `673cc1e0dfd50936a8cd07e5c57da9329bd2b4e0`.

AirReclaim changes are intentionally limited to:

- public signer layout and styling;
- completed, declined, expired, archived, awaiting, delegated, and success presentation;
- signer invitation, completion, decline, OTP, and document-copy email presentation;
- canonical authorized-signer completed downloads with fresh five-minute document URLs and accessible retry handling;
- text-only DocuSeal attribution and corresponding-source link;
- deterministic deployment, backup, source-archive, and verification tooling.

The DocuSeal submission engine, signing endpoints, field state, CSRF handling, PDF generation, audit trail, certificate handling, API payloads, and webhooks are not modified.

## License and source

DocuSeal is distributed under the GNU Affero General Public License version 3 with Section 7(b) additional attribution terms. The original `LICENSE` and `LICENSE_ADDITIONAL_TERMS` files are retained. The deployed signer includes visible text-only DocuSeal attribution.

Build the image and corresponding-source archive with:

```sh
bash ops/airreclaim/build-release.sh
```

The script refuses a dirty checkout, builds the exact checked-out source, exports a source archive, and writes SHA-256 checksums. The resulting image must be published under an immutable registry digest before production use.

To prepare and verify only the corresponding-source package on a machine without Docker, run `bash ops/airreclaim/build-release.sh --source-only`. This does not satisfy the image-build or digest-recording release gates.
