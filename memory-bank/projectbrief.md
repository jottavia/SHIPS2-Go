# Project Brief: SHIPS2-Go

## Core Problem
Small IT shops without an Active Directory domain lack a simple, secure way to manage local Administrator passwords and BitLocker recovery keys across their Windows workstations. This leads to password divergence, security risks, and operational headaches when administrative access is needed.

## Solution: SHIPS2-Go
SHIPS2-Go is a zero-cost, self-hosted, single-binary solution written in Go that provides a lightweight alternative to Microsoft LAPS. It automates password rotation and escrows BitLocker keys, making them retrievable through a secure, audited SSH-based workflow.

## Key Features
- **Automated Password Rotation:** Daily rotation of the local *Administrator* password.
- **BitLocker Key Escrow:** Securely stores and provides access to BitLocker recovery keys.
- **Secure Access Model:** All operator access is funneled through a restricted SSH command wrapper (`shipsc_wrapper.sh`), not direct API exposure. The API server (`ships-server`) listens only on localhost.
- **Comprehensive Auditing:** Every password or key retrieval is logged to syslog and can be integrated with Wazuh for real-time security monitoring.
- **Lightweight & Simple:** No domain, Docker, or external database dependencies. It's just a Go binary for the server and one for the client, using an embedded SQLite database.
- **Optional Authentication:** Supports HTTP Basic Auth for an added layer of security on the API.

## High-Level Architecture
- **Server (Linux):** A `ships-server` binary runs as a systemd service, listening on `127.0.0.1:8080`. It uses a local SQLite database for storage.
- **Client (Windows):** A `shipsc.exe` binary is run via a Scheduled Task to rotate the password and update the key on the server.
- **Operator Access:** Authorized users SSH into the server, where their command is forced through the `shipsc_wrapper.sh` script, which validates input and calls the local API.

## Target Audience
IT administrators in small to medium-sized businesses, particularly those managing Windows workgroups without a full Active Directory setup.
