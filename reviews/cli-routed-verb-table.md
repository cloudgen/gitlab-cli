# CLI routed-verb table — gitlab-cli

Human-readable column = main-menu labels (`command: what it does`).

| Routed-verb | Live | Privilege | Human-readable | Main menu? | Notes |
|-------------|------|-----------|----------------|------------|-------|
| *(empty argv)* | yes | Type 0 | — | TTY = menu; pipe = install-ensure | overlay flags follow empty argv |
| `install` | yes | Type 0 | install: Place the CLI binary | no | self-managed |
| `version` | yes | Type 0 | version: Show current version | no | diagnostics |
| `about` | yes | Type 0 | about: Show diagnostics | no | diagnostics |
| `help` | yes | Type 0 | help: Show this help | no | excluded |
| `version-check` | yes | Type 0 | version-check: Compare local vs remote version | no | self-managed |
| `self-update` | yes | Type 0 | self-update: Update this program | no | self-managed |
| `self-uninstall` | yes | Type 0 | self-uninstall: Remove this program | no | self-managed |
| `menu` | yes | Type 0 | menu: Numbered list of live work commands | no | opener |
| `main` | yes | Type 0 | main: Alias of menu | no | alias |
| `list-users` | yes | root | list-users: List GitLab users | **1** | operational |
| `reset-password` | yes | root | reset-password: Reset a GitLab user password (numbered list first) | **2** | operational |
| `status` | yes | root | status: Show gitlab-ctl status | **3** | operational |
| `setup` | yes | root | setup: Create gitlab-adm least-privilege operator (no Nginx) | no | host setup excluded |
| `remove-lpu` | yes | root | remove-lpu: Remove gitlab-adm (confirm or --force) | **4** | operational |
| `remove-gitlab-adm` | yes | root | — | no | alias of remove-lpu |

Exit **9**. Invalid choice retries this layer (**TP-CLI-19**).
