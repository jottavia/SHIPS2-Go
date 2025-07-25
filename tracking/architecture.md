# SHIPS2-Go Architecture Documentation

## System Architecture

### High-Level Design

SHIPS2-Go follows a client-server architecture designed for security, simplicity, and auditability:

```
┌─────────────────────┐    ┌─────────────────────┐    ┌─────────────────────┐
│   Windows Clients   │    │   Linux Server      │    │   Monitoring        │
│                     │    │                     │    │                     │
│ ┌─────────────────┐ │    │ ┌─────────────────┐ │    │ ┌─────────────────┐ │
│ │   shipsc.exe    │ │    │ │  ships-server   │ │    │ │     Wazuh       │ │
│ │                 │ │────┼▶│                 │ │────┼▶│   (Rules        │ │
│ │ • Password Gen  │ │    │ │ • HTTP API      │ │    │ │    91000-91005) │ │
│ │ • BitLocker Key │ │    │ │ • SQLite Store  │ │    │ │                 │ │
│ │ • Scheduled     │ │    │ │ • Audit Log     │ │    │ └─────────────────┘ │
│ └─────────────────┘ │    │ └─────────────────┘ │    │                     │
│                     │    │          │          │    │ ┌─────────────────┐ │
└─────────────────────┘    │          ▼          │    │ │    rsyslog      │ │
           │                │ ┌─────────────────┐ │    │ │   Forwarding    │ │
           │                │ │ shipsc_wrapper  │ │    │ │                 │ │
           │                │ │                 │ │────┼▶│ • SSH Logs      │ │
           │                │ • Input Valid.    │ │    │ │ • JSON Format   │ │
           │                │ • Command Filter  │ │    │ │ • Event Stream  │ │
           │                │ • Audit Logging   │ │    │ └─────────────────┘ │
           │                └─────────────────────┘    └─────────────────────┘
           │                          ▲
           └──────────SSH Port 22──────┘
```

### Component Responsibilities

#### Client Components (`shipsc.exe`)
- **Password Generation**: Creates secure random passwords
- **BitLocker Integration**: Extracts recovery keys using PowerShell
- **HTTP Client**: Communicates with server API
- **Error Handling**: Robust retry logic and logging
- **Scheduled Execution**: Runs via Windows Task Scheduler

#### Server Components (`ships-server`)
- **HTTP API Server**: Gin-based REST API with proper error handling
- **Authentication**: Optional HTTP Basic Auth
- **Data Store**: SQLite database with WAL mode for concurrency
- **Audit Logging**: Complete trail of all operations
- **Input Validation**: Sanitizes and validates all inputs

#### SSH Wrapper (`shipsc_wrapper.sh`)
- **Command Filtering**: Only allows `fetch`, `rotate`, `bde` commands
- **Input Validation**: Validates hostnames and passwords
- **Audit Logging**: Structured JSON logging for all access
- **Security Enforcement**: Prevents command injection and abuse

#### Monitoring Integration
- **rsyslog**: Forwards SSH wrapper logs to Wazuh
- **Wazuh Rules**: Monitors for suspicious patterns and access
- **Alert Generation**: Real-time security event notifications

## Data Flow

### Password Rotation Flow

1. **Windows Client** (Scheduled Task):
   ```
   shipsc.exe rotate HOSTNAME [password] -actor ScheduledTask
   ```

2. **HTTP Request** to server:
   ```json
   POST /api/v1/rotate
   {
     "host": "HOSTNAME",
     "password": "generated_password",
     "actor": "ScheduledTask"
   }
   ```

3. **Server Processing**:
   - Validates hostname format
   - Validates password complexity
   - Stores in SQLite database
   - Creates audit log entry
   - Returns success response

4. **Audit Trail**:
   - Database audit log with timestamp, actor, remote IP
   - Application logs via structured logging

### Password Retrieval Flow

1. **SSH Access**:
   ```bash
   ssh shipscmd@server fetch HOSTNAME
   ```

2. **SSH Wrapper**:
   - Validates command format
   - Validates hostname format
   - Logs access attempt
   - Executes local shipsc command

3. **Local API Call**:
   ```
   /opt/ships/bin/shipsc fetch HOSTNAME
   ```

4. **HTTP Request**:
   ```
   GET /api/v1/password/HOSTNAME
   ```

5. **Server Response**:
   ```json
   {
     "password": "current_password",
     "rotated_at": "2025-07-19T10:30:00Z",
     "actor": "ScheduledTask"
   }
   ```

6. **Audit Logging**:
   - SSH wrapper logs to syslog
   - Database audit entry
   - Wazuh rule processing

## Security Architecture

### Defense in Depth

1. **Network Layer**:
   - Server binds only to localhost (127.0.0.1)
   - Only SSH port 22 exposed externally
   - No direct external access to API

2. **Authentication Layer**:
   - Optional HTTP Basic Auth for API
   - SSH key-based authentication for operators
   - ForceCommand restriction in SSH

3. **Authorization Layer**:
   - SSH wrapper enforces command restrictions
   - Input validation prevents injection attacks
   - Actor tracking for accountability

4. **Application Layer**:
   - Comprehensive input validation
   - SQL injection prevention via prepared statements
   - Error handling without information disclosure

5. **Audit Layer**:
   - Complete audit trail in database
   - Structured logging for security monitoring
   - Real-time alerting via Wazuh

### Security Controls

| Control Type | Implementation | Purpose |
|--------------|----------------|---------|
| **Access Control** | SSH keys + ForceCommand | Restrict who can access system |
| **Command Control** | SSH wrapper validation | Limit what commands can be run |
| **Input Validation** | Hostname/password checks | Prevent injection attacks |
| **Audit Logging** | Database + syslog | Track all access and changes |
| **Rate Limiting** | Wazuh rule 91005 | Detect suspicious access patterns |
| **Authentication** | HTTP Basic Auth | Protect API endpoints |
| **Network Isolation** | Localhost binding | Prevent external API access |

## Database Design

### Schema Philosophy

The database schema is designed for:
- **Simplicity**: Minimal tables with clear relationships
- **Auditability**: Complete history of all operations
- **Performance**: Efficient queries with proper indexing
- **Integrity**: Foreign key constraints and validation

### Table Relationships

```
machines (1) ──┐
               ├─── passwords (1:1)
               ├─── bitlocker_keys (1:1)  
               └─── audit_logs (1:N)
```

### Data Retention

- **Passwords**: Only current password stored (REPLACE semantics)
- **BitLocker Keys**: Only current key stored (REPLACE semantics)
- **Audit Logs**: Retained indefinitely (consider archival policy)
- **Machine Records**: Retained indefinitely for historical reference

## API Design

### RESTful Principles

- **Resource-based URLs**: `/api/v1/password/HOSTNAME`
- **HTTP Methods**: GET for retrieval, POST for updates
- **Status Codes**: Proper HTTP status codes for different scenarios
- **JSON Format**: Consistent JSON request/response format

### Error Handling

```json
{
  "error": "descriptive error message",
  "code": "ERROR_CODE",
  "timestamp": "2025-07-19T10:30:00Z"
}
```

### Versioning Strategy

- **URL-based versioning**: `/api/v1/...`
- **Backward compatibility**: v1 API maintained for existing clients
- **Future versions**: `/api/v2/...` for breaking changes

## Monitoring Architecture

### Log Aggregation Flow

```
SSH Wrapper ──┐
              ├─── rsyslog ──── Wazuh ──── Alerts
Server Logs ──┘
```

### Alert Categories

1. **Security Alerts** (High Priority):
   - Multiple failed access attempts
   - Access from unusual IP addresses
   - Attempts to use unauthorized commands

2. **Operational Alerts** (Medium Priority):
   - Service failures or restarts
   - Database connection issues
   - Client rotation failures

3. **Audit Events** (Low Priority):
   - Normal password/key access
   - Successful rotations
   - System health checks

### Metrics Collection

Key metrics to monitor:
- **Access Frequency**: Passwords/keys accessed per hour/day
- **Rotation Success Rate**: Percentage of successful rotations
- **Response Times**: API response time percentiles
- **Error Rates**: HTTP 4xx/5xx response rates
- **Client Health**: Last successful rotation per client

## Deployment Architecture

### Production Environment

```
┌─────────────────────────────────────────────┐
│                Load Balancer                │
│            (Optional - SSH LB)              │
└─────────────────┬───────────────────────────┘
                  │
┌─────────────────▼───────────────────────────┐
│              Linux Server                   │
│                                            │
│ ┌─────────────┐  ┌─────────────┐          │
│ │ ships-server│  │ shipsc      │          │
│ │ (systemd)   │  │ wrapper     │          │
│ └─────────────┘  └─────────────┘          │
│                                            │
│ ┌─────────────┐  ┌─────────────┐          │
│ │ SQLite DB   │  │ rsyslog     │          │
│ │ (WAL mode)  │  │ (forwarding)│          │
│ └─────────────┘  └─────────────┘          │
└────────────────────────────────────────────┘
```

### High Availability Considerations

While SHIPS2-Go is designed for simplicity, high availability can be achieved through:

1. **Database Replication**: SQLite with periodic backups
2. **Server Redundancy**: Multiple server instances with shared storage
3. **Health Monitoring**: Automated failover based on health checks
4. **Backup Strategy**: Regular database and configuration backups

## Future Architecture Considerations

### Scalability Enhancements

1. **PostgreSQL Migration**: For larger deployments requiring concurrent access
2. **Microservices**: Split into separate auth, audit, and data services
3. **Container Deployment**: Docker/Kubernetes for easier scaling
4. **API Gateway**: Centralized authentication and rate limiting

### Security Enhancements

1. **mTLS Authentication**: Certificate-based client authentication
2. **Encryption at Rest**: SQLCipher for database encryption
3. **HSM Integration**: Hardware security modules for key management
4. **RBAC**: Role-based access control for different operator levels

### Monitoring Enhancements

1. **Metrics Export**: Prometheus/Grafana integration
2. **Distributed Tracing**: OpenTelemetry for request tracing
3. **Machine Learning**: Anomaly detection for access patterns
4. **Compliance Reporting**: Automated compliance report generation
