# Tech Context: SHIPS2-Go

## Core Technologies
-   **Programming Language:** Go (version 1.22+) is used for its performance, cross-compilation capabilities, and suitability for creating single-binary applications.
-   **Database:** SQLite is the embedded database, chosen for its simplicity and lack of external dependencies.
-   **API Framework:** The Gin web framework is used for building the HTTP API, providing routing and request handling.
-   **Shell Scripting:** Bash is used for the `shipsc_wrapper.sh` and deployment scripts, providing a simple and ubiquitous tool for server-side automation.

## Development Environment
-   **Build System:** A `Makefile` is provided to standardize development and build tasks. Key commands include:
    -   `make build`: Compiles the server and client for the local OS.
    -   `make windows`: Cross-compiles the client for Windows.
    -   `make lint`: Runs `golangci-lint` to enforce code quality.
    -   `make release`: Creates release-ready artifacts.
-   **Linting:** `golangci-lint` is the standard for ensuring code quality and consistency.
-   **Static Analysis:** `staticcheck` is used to find bugs and performance issues.
-   **Formatting:** `gofmt` is used for automatic code formatting.

## Technical Constraints & Considerations
-   **Cross-Platform Client:** The `shipsc` client must be compilable for Windows, as it is the target platform for password rotation. The server is designed for a Linux environment.
-   **No CGO (by default):** The Go build process should avoid CGO where possible to maintain the simplicity of cross-compilation, although the use of SQLite may require it.
-   **Security Hardening:** All components must be designed with security in mind. This includes input validation, restricted permissions, and secure-by-default configurations.
-   **Backwards Compatibility:** Future changes to the API should consider backwards compatibility with existing clients, or a clear versioning and upgrade path must be provided.
-   **Wazuh Integration:** The format of the JSON logs is a critical part of the system's monitoring capabilities. Any changes to the log structure must be reflected in the Wazuh rules.
