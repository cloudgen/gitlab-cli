# Security Policy

## Supported Versions

| Version | Supported |
|---------|-----------|
| **1.0.1** (current) | Yes — full support |
| **1.0.0** | Yes |
| gitlab-nginx 2.x lineage | Not this product; this CLI is a stripped GitLab-operator fork |

## Reporting a Vulnerability

Please **do not** open a public issue for security-sensitive reports when a private channel is available.

**Maintainer contact (email):** `wongcf22@gmail.com`

- Source of contact: product **author-email** SSOT in [`LICENSE.md`](./LICENSE.md) (Copyright line).
- Prefer email for vulnerability details, reproduction steps, and impact.
- You should receive an acknowledgment when the report is received and actionable.
- Do not include exploit weaponization guides in public channels.

For non-sensitive questions or general bugs, use normal project channels (for example public issues on the project repository when available).

## Security Design Principles (CIAO)

This project follows **[CIAO](https://github.com/cloudgen/ciao)** / **CIAO-Lite** defensive design. Security-relevant intent:

| Letter | Principle | Security application |
|--------|-----------|----------------------|
| **C** | **Caution** | Assume hostile input. Validate usernames passed to `gitlab-rails`. Fail closed when not root. Fail closed on integrity **mismatch** when a companion digest is present. Password reset does not print the new password. |
| **I** | **Intentional** | Self-management as yourself, channel URL (`SCRIPT_URL`), automatic companion-checksum, and GitLab operator verbs (`list-users`, `reset-password`, `status`, `setup`, `remove-lpu`) are deliberate. Prefer clear “why” over silent magic. |
| **A** | **Anti-fragile** | Survive harsh environments (minimal containers, non-interactive `curl \| sh`). Prefer transparent automatic SHA-256 sidecar checks, least privilege for day-to-day CLI use, and recoverable failure over brittle trust. |
| **O** | **Over-protect** | Defense in depth on critical paths (integrity verify before install/update when designed, `gitlab-adm` least-privilege, loud failure). Do not “simplify away” safety for brevity. |

Full principles: [CIAO Defensive Programming](https://github.com/cloudgen/ciao) · agent contract: [CIAO-Lite](https://github.com/cloudgen/ciao-lite).

This section describes **design posture**. It is **not** a claim of third-party certification (ISO, OWASP “compliant”, etc.).

## Install integrity and trust

When this product implements the **automatic checksum mechanism** (program fetches a companion digest next to the install artifact):

| Fact | Honest statement |
|------|------------------|
| **Default path** | Automatic companion verification (`${SCRIPT_URL}.sha256`) when no operator pin is set — **no** env pin required for normal install/self-update. |
| **Algorithm** | SHA-256 (`sha256sum`). |
| **Transparency** | Human mode is designed to show companion **link**, expected **value**, and verification **result** (match / mismatch / missing). |
| **Mismatch** | Abort — do not install mismatched bytes. |
| **Missing sidecar** | Warning, then continue (best-effort). Never claim “always verified”. |
| **Optional pin** | Process-env `CHECKSUM` is **secondary** (CI / out-of-band freeze). It is **not** stronger than automatic mode when the pin is fetched from the **same origin**. Do **not** advertise it in `help` / `about`. |
| **Trust bound** | Same-channel SHA-256 proves **byte consistency**. It is **not** independent authenticity (signing / separate trust root) by itself. |

Operator-facing install steps live in [`README.md`](./README.md).

## Scope notes

- Preferred languages for reports: English.
- Out of scope: social engineering of third parties, physical attacks, spam.
- Related product docs: [`README.md`](./README.md), [`LICENSE.md`](./LICENSE.md).
