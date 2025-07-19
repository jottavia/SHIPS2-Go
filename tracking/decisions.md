# SHIPS2-Go Technical Decisions Log

This document tracks major technical decisions made during the development and fixes of SHIPS2-Go.

## Decision Log

### 2025-07-19: API Response Format Standardization
**Decision**: Standardize API responses to match client expectations and include metadata
**Context**: Original API responses had inconsistent field names and missing metadata
**Options Considered**:
1. Change client to match server responses
2. Change server to match client expectations
3. Create transformation layer

**Decision**: Option 2 - Change server to match client expectations
**Reasoning**: 
- Client expectations were more logical and complete
- Included necessary metadata (timestamps, actors)
- Consistent with REST API best practices
- Fewer breaking changes for end users

**Implementation**:
- Modified API handlers to return proper JSON structures
- Added PasswordInfo and BitLockerKeyInfo structs
- Updated store methods to return complete metadata

---

### 2025-07-19: Authentication Strategy
**Decision**: Implement optional HTTP Basic Auth for API endpoints
**Context**: Original design had no authentication, relying solely on localhost binding
**Options Considered**:
1. No authentication (original approach)
2. HTTP Basic Auth
3. JWT tokens
4. API keys
5. mTLS certificates

**Decision**: Option 2 - HTTP Basic Auth
**Reasoning**:
- Simple to implement and configure
- Widely supported by HTTP clients
- Optional nature maintains backward compatibility
- Sufficient security for localhost-bound API
- Easy to integrate with existing deployment scripts

**Implementation**:
- Added SHIPS_AUTH_USER and SHIPS_AUTH_PASS environment variables
- Implemented basicAuthMiddleware with timing attack protection
- Updated deployment scripts to support auth configuration

---

### 2025-07-19: Audit Logging Enhancement
**Decision**: Implement comprehensive audit logging with remote IP tracking
**Context**: Original audit logging was incomplete and lacked security context
**Options Considered**:
1. Minimal audit logging (original)
2. Database-only audit logging
3. Comprehensive audit with syslog integration
4. External audit service integration

**Decision**: Option 3 - Comprehensive audit with syslog integration
**Reasoning**:
- Meets compliance requirements for access tracking
- Integrates well with existing Wazuh monitoring
- Provides both local storage and remote forwarding
- Enables real-time security monitoring
- Includes all necessary context (actor, IP, timestamp)

**Implementation**:
- Added remote_addr field to audit_logs table
- Modified store methods to accept and log remote addresses
- Enhanced API handlers to extract client IP addresses
- Updated SSH wrapper to log structured JSON events

---

### 2025-07-19: Input Validation Strategy
**Decision**: Implement comprehensive input validation at all entry points
**Context**: Original code had minimal input validation, creating security risks
**Options Considered**:
1. Client-side validation only
2. Server-side validation only
3. Validation at all layers
4. Schema-based validation

**Decision**: Option 3 - Validation at all layers
**Reasoning**:
- Defense in depth security principle
- Prevents various injection attacks
- Improves user experience with early error detection
- Provides multiple failsafes
- Essential for production security

**Implementation**:
- Added validateHostname and validatePassword functions
- Enhanced SSH wrapper with input sanitization
- Implemented proper error messages for validation failures
- Added length and character restrictions

---

### 2025-07-19: Database Schema Updates
**Decision**: Add missing fields and improve schema consistency
**Context**: Schema documentation didn't match implementation, missing audit fields
**Options Considered**:
1. Update documentation to match implementation
2. Update implementation to match documentation
3. Redesign schema completely
4. Add missing fields to existing schema

**Decision**: Option 4 - Add missing fields to existing schema
**Reasoning**:
- Preserves existing data and compatibility
- Adds necessary audit fields
- Maintains simple, efficient design
- Minimal migration complexity

**Implementation**:
- Added actor field to passwords and bitlocker_keys tables
- Added remote_addr field to audit_logs table
- Added first_seen field to machines table
- Updated documentation to match final schema

---

### 2025-07-19: Error Handling Strategy
**Decision**: Implement consistent error handling with proper HTTP status codes
**Context**: Original error handling was inconsistent and leaked internal details
**Options Considered**:
1. Generic error messages
2. Detailed error messages
3. Structured error responses
4. Error codes with lookup

**Decision**: Option 3 - Structured error responses
**Reasoning**:
- Provides useful debugging information
- Maintains security by not leaking internals
- Consistent format for client handling
- Enables proper error categorization

**Implementation**:
- Standardized JSON error response format
- Proper HTTP status codes (400, 404, 500)
- Descriptive but secure error messages
- Enhanced client error handling and display

---

### 2025-07-19: Build System Standardization
**Decision**: Rename makefile.txt to Makefile and enhance build targets
**Context**: Non-standard filename prevented proper make integration
**Options Considered**:
1. Keep makefile.txt for Windows compatibility
2. Rename to Makefile
3. Support both filenames
4. Switch to different build system

**Decision**: Option 2 - Rename to Makefile
**Reasoning**:
- Standard Unix convention
- Better IDE and tool support
- Enables proper make integration
- Windows developers can use WSL or Git Bash
- Industry standard approach

**Implementation**:
- Renamed makefile.txt to Makefile
- Enhanced build targets with version support
- Added development tool installation
- Improved cross-platform build support

---

### 2025-07-19: Deployment Script Improvements
**Decision**: Create production-ready deployment scripts with proper configuration
**Context**: Original scripts had placeholder URLs and minimal functionality
**Options Considered**:
1. Fix existing scripts
2. Rewrite deployment scripts
3. Use configuration management tools
4. Manual deployment documentation

**Decision**: Option 2 - Rewrite deployment scripts
**Reasoning**:
- Needed comprehensive production features
- Required proper error handling and validation
- Opportunity to add authentication and monitoring setup
- Better user experience for deployment

**Implementation**:
- Complete rewrite of deploy_ships_server.sh
- Added support for authentication configuration
- Integrated Wazuh setup options
- Enhanced error handling and validation
- Added comprehensive setup verification

---

### 2025-07-19: SSH Wrapper Security Enhancements
**Decision**: Implement robust input validation and security controls in SSH wrapper
**Context**: Original wrapper had basic filtering but lacked comprehensive security
**Options Considered**:
1. Basic command filtering (original)
2. Enhanced input validation
3. Complete command parser
4. Restricted shell environment

**Decision**: Option 2 - Enhanced input validation
**Reasoning**:
- Maintains simplicity while improving security
- Prevents common injection attacks
- Provides clear error messages
- Enables comprehensive audit logging
- Balanced approach between security and usability

**Implementation**:
- Added validate_hostname and validate_password functions
- Implemented JSON structured logging
- Enhanced error handling and user feedback
- Added command argument validation
- Improved security against shell injection

---

## Decision Criteria

When making technical decisions for SHIPS2-Go, we prioritize:

1. **Security First**: All decisions evaluated for security implications
2. **Simplicity**: Prefer simple solutions that are easy to understand and maintain
3. **Backward Compatibility**: Minimize breaking changes for existing users
4. **Production Readiness**: Ensure solutions work reliably in production environments
5. **Auditability**: Enable comprehensive tracking and monitoring
6. **Standards Compliance**: Follow industry standards and best practices

## Future Decisions

### Pending Decisions

1. **Database Migration Strategy**: Plan for PostgreSQL migration for larger deployments
2. **Container Strategy**: Docker/Kubernetes deployment options
3. **API Versioning**: Strategy for future API versions
4. **Encryption at Rest**: SQLCipher integration timeline
5. **High Availability**: Multi-server deployment architecture

### Decision Framework

For future technical decisions, use this framework:

1. **Document the Context**: What problem are we solving?
2. **List Options**: What are the viable alternatives?
3. **Define Criteria**: What factors are most important?
4. **Analyze Trade-offs**: Pros and cons of each option
5. **Make Decision**: Select option with clear reasoning
6. **Plan Implementation**: How will we execute the decision?
7. **Monitor Outcomes**: How will we measure success?

## Lessons Learned

### What Worked Well

1. **Comprehensive Analysis**: Taking time to identify all issues prevented partial fixes
2. **Systematic Approach**: Fixing related issues together reduced overall complexity
3. **Documentation Updates**: Keeping docs in sync prevented future confusion
4. **Security Focus**: Prioritizing security from the start avoided retrofit challenges

### What Could Be Improved

1. **Testing Strategy**: More comprehensive testing could have caught issues earlier
2. **Code Review Process**: Formal review process might have identified problems sooner
3. **Migration Planning**: Better planning for schema changes would reduce complexity
4. **User Communication**: Clear communication about breaking changes is essential

### Best Practices Established

1. **API Compatibility**: Always maintain backward compatibility when possible
2. **Security by Default**: Implement security controls by default, make them optional to disable
3. **Comprehensive Logging**: Log everything needed for security and debugging
4. **Input Validation**: Validate all inputs at all layers
5. **Documentation Accuracy**: Keep documentation current with implementation