# Repository Layout – SHIPS‑Go / SHIPS2‑Go

> **Purpose:** High‑level directory tree so that anyone armed with this file and an LLM can reconstruct the entire repository structure.

```text
ships-go/
│  .gitignore              # Standard Go / editor artefacts
│  go.mod                  # Module definition – minimal deps (Gin, SQLite)
│  go.sum                  # Checksums for dependencies
│  Makefile                # Convenience targets: build, lint, test, cross‑compile
│  LICENSE                 # MIT (Joseph V. Ottaviano, 2025)
│  README.md               # Exhaustive project guide
│
├─ cmd/                    # Entrypoints (each builds its own binary)
│   ├─ server/
│   │    └─ main.go        # ships‑server HTTP API
│   └─ client/
│        └─ main.go        # shipsc CLI (rotate / fetch / bde)
│
├─ internal/               # Library packages (import‑able only inside module)
│   ├─ api/
│   │    └─ api.go         # Gin router + handlers
│   └─ store/
│        └─ store.go       # SQLite logic (schema & CRUD)
│
├─ bin/                    # Runtime helper scripts
│   └─ shipsc_wrapper.sh   # Forced‑command SSH wrapper
│
├─ deploy/                 # One‑shot install helpers (copy‑&‑paste‑able)
│   ├─ deploy_ships_server.sh       # Installs binaries, systemd, wrapper
│   ├─ deploy_rsyslog_shipsc.sh     # Adds rsyslog drop‑in for audit→Wazuh
│   └─ deploy_wazuh_local_rules.sh  # Installs custom Wazuh rule 91000
│
├─ docs/                   # Human‑readable docs & templates
│   ├─ project_overview_latest.md   # Canonical spec (this repo’s contract)
│   ├─ wazuh_integration_latest.md  # SIEM integration how‑to
│   ├─ client_task.xml              # Scheduled Task for Windows 11
│   └─ repo_layout.md               # **this file**
│
└─ tests/ (optional)       # <future> Go test fixtures & integration harness
```

> **Note:** The tree above is generated manually—if you add/remove items, please update this file accordingly to keep the “single‑file reconstruction” guarantee.

