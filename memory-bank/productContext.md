# Product Context: SHIPS2-Go

## The "Why"
SHIPS2-Go exists to fill a critical gap for IT professionals managing fleets of Windows computers in non-domain environments. In a typical workgroup setup, managing local administrator passwords is a manual, insecure, and error-prone process. Passwords are either all the same (a major security risk) or they diverge over time, leading to situations where an administrator can be locked out of a machine when they need access most. Similarly, BitLocker recovery keys, critical for data recovery, are often stored in insecure locations or not tracked at all.

This project provides a robust, secure, and automated solution that is simple to deploy and manage, specifically designed for environments where enterprise-level tools like Microsoft LAPS are not an option.

## Problem Solved
SHIPS2-Go directly solves the following problems:
1.  **Password Sprawl:** Eliminates the need for identical, static local administrator passwords across multiple machines.
2.  **Lockout Risk:** Prevents administrators from being unable to access a machine due to a lost or unknown password.
3.  **Insecure Key Storage:** Provides a centralized, secure escrow for BitLocker recovery keys, instead of relying on spreadsheets, text files, or physical documents.
4.  **Lack of Auditing:** Introduces a clear, auditable trail for when and by whom passwords and keys are accessed, a feature often missing in small-scale IT operations.
5.  **Complexity Overhead:** Replaces complex, dependency-heavy solutions with a lightweight, single-binary tool that is easy to install and maintain.

## User Experience Goals
-   **Simplicity:** The entire system should be deployable with a single command. Both the server and client components are single binaries with no external dependencies.
-   **Security by Default:** The system is designed to be secure out of the box. The API is not exposed to the network, and all access is forced through a hardened SSH wrapper.
-   **Frictionless for Operators:** Authorized IT staff should be able to retrieve a password or key with a simple, intuitive SSH command (e.g., `ssh shipscmd@server fetch-password WIN-PC-01`).
-   **Transparent for End-Users:** The client-side password rotation should be completely invisible to the end-user and have no impact on their workflow.
-   **Actionable Auditing:** The audit logs should be clear, structured (JSON), and easily integrated with monitoring tools like Wazuh to provide meaningful security alerts.
