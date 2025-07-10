# 🏗️ Technical Decisions - Multi-User Health Tracker

> **Purpose**: Document all major technical architecture decisions, rationale, and implications for future development.

---

## 📋 **Decision Template**

```markdown
### Decision: [Decision Name]
**Date**: [Date]
**Status**: [Confirmed/Under Review/Deprecated]

**Context**: Brief description of the problem or choice that needed to be made.

**Options Considered**:
1. Option A - Brief description
2. Option B - Brief description
3. Option C - Brief description

**Decision**: Chosen option and brief rationale.

**Rationale**:
- Reason 1
- Reason 2
- Reason 3

**Implications**:
- Technical impact
- Development timeline impact
- Scalability considerations
- Future migration considerations

**Implementation Notes**:
- Key implementation details
- Dependencies
- Potential risks

---
```

---

## 🎯 **Confirmed Decisions**

### Decision: Form Validation Approach
**Date**: July 5, 2025
**Status**: Confirmed

**Context**: Need to implement user registration form with proper validation and good user experience.

**Options Considered**:
1. **Schema-based validation** - Use PSU form schema with built-in validation
2. **OnValidate callbacks** - Custom validation with real-time feedback
3. **Custom component forms** - Build custom React components with validation

**Decision**: Schema-based validation (Option 1)

**Rationale**:
- Better user experience - no annoying live validation interruptions
- Built-in validation handling by PSU framework
- Consistent with PSU best practices
- Faster development time
- Professional appearance out of the box

**Implications**:
- All form validation must be defined in schema
- Cannot use `-Required` parameter on individual controls
- Validation errors shown on form submission, not real-time
- Easier to maintain and extend

**Implementation Notes**:
- Use `required: true` in schema properties
- Email validation with `format: "email"`
- Password strength with `minLength: 8`
- Checkbox validation for terms of service

---

### Decision: User Storage Strategy (Phase 1)
**Date**: July 5, 2025
**Status**: Confirmed

**Context**: Need to store user accounts, profiles, and health data for multi-user system.

**Options Considered**:
1. **JSON files only** - User data stored in structured JSON files
2. **SQLite database** - Lightweight database for all user data
3. **PostgreSQL database** - Full database solution from start
4. **Hybrid approach** - Database for users, JSON for health data

**Decision**: JSON files only (Option 1) for Phase 1

**Rationale**:
- Rapid prototyping and development
- No database setup complexity initially
- Easy to debug and inspect data
- Maintains existing health data structure
- Can migrate to database later without changing user interface
- Simpler backup and data portability

**Implications**:
- Manual email uniqueness checking required
- File system-based user management
- No SQL queries or complex relationships initially
- Future migration to database needed for scale
- File locking considerations for concurrent access

**Implementation Notes**:
- User directory structure: `/data/users/{userId}/`
- Files: `profile.json`, `preferences.json`, `health-data/entries.json`
- GUID-based user IDs for security and uniqueness
- JSON validation and error handling required

---

### Decision: User ID Format
**Date**: July 5, 2025
**Status**: Confirmed

**Context**: Need unique, secure user identifiers for file system storage and future database migration.

**Options Considered**:
1. **Sequential integers** - Simple auto-incrementing IDs
2. **UUIDs/GUIDs** - Globally unique identifiers
3. **Email-based hashing** - Hash of user email as ID
4. **Random alphanumeric** - Custom random string generation

**Decision**: UUIDs/GUIDs (Option 2)

**Rationale**:
- Globally unique without coordination
- Not predictable or enumerable (security)
- Standard format with good tooling support
- Future-proof for distributed systems
- Easy to generate in PowerShell with `[System.Guid]::NewGuid()`

**Implications**:
- Longer identifiers in URLs and file paths
- No meaningful ordering (not chronological)
- Requires GUID validation in code
- Standard format aids in debugging

**Implementation Notes**:
- Generate with `[System.Guid]::NewGuid().ToString()`
- Use as directory name: `/data/users/{guid}/`
- Store in profile.json for reference
- Validate GUID format in user management functions

---

### Decision: Authentication Method (Phase 1)
**Date**: July 5, 2025
**Status**: Confirmed

**Context**: Need user authentication system that integrates with PowerShell Universal and custom user storage.

**Options Considered**:
1. **PSU Local Accounts only** - Use built-in PSU user management
2. **Custom Forms Authentication only** - Build entirely custom auth system
3. **Hybrid approach** - PSU Local Accounts + Custom Forms Authentication
4. **External OAuth** - Azure AD, Auth0, etc.

**Decision**: Hybrid approach (Option 3)

**Rationale**:
- Leverages PSU's session management capabilities
- Allows custom user registration and profile management
- Easier to implement than pure custom auth
- Can integrate with existing PSU security features
- Provides foundation for future OAuth integration

**Implications**:
- Need to sync custom user data with PSU local accounts
- Custom registration process creates PSU accounts
- Session management handled by PSU framework
- User profile data stored separately from PSU user data

**Implementation Notes**:
- Create PSU local account during registration
- Store extended profile data in custom JSON files
- Use PSU's `Set-PSUAuthenticationResult` for login
- Implement custom password hashing for security

---

### Decision: Data Architecture Pattern
**Date**: July 5, 2025
**Status**: Confirmed

**Context**: Need organized, scalable data structure for user-isolated health tracking data.

**Options Considered**:
1. **Single shared data structure** - All users in same files
2. **User-isolated directories** - Separate folder per user
3. **Hybrid flat files** - User prefix in filenames
4. **Database with user partitioning** - Database tables with user columns

**Decision**: User-isolated directories (Option 2)

**Rationale**:
- Clear data isolation and privacy
- Easy backup and restore per user
- Simplified file permissions and security
- Mirrors existing single-user structure
- Easy to migrate to database later
- Supports user data export requirements

**Implications**:
- Directory creation required during registration
- File path management includes user ID
- Backup strategy per user or bulk
- File system permissions important

**Implementation Notes**:
- Structure: `/data/users/{userId}/profile.json`, `preferences.json`, `health-data/`
- Copy existing entries.json structure to user directories
- Create utility functions for user data path resolution
- Implement directory cleanup for account deletion

---

## 🔄 **Under Review**

### Decision: Frontend Framework Enhancement
**Status**: Under Review

**Context**: Current Universal Dashboard may need enhancement for modern mobile-first user experience.

**Options Being Considered**:
1. Continue with Universal Dashboard + custom styling
2. Add React components for complex interactions
3. Implement Progressive Web App features
4. Create separate mobile app

**Next Steps**: Evaluate after Phase 1 completion

---

### Decision: Real-time Notifications
**Status**: Under Review

**Context**: Users will need medication reminders and health check-in notifications.

**Options Being Considered**:
1. Email-based notifications
2. Browser push notifications
3. SMS integration
4. Mobile app notifications

**Next Steps**: Research browser notification APIs and user preferences

---

## 🚫 **Deprecated Decisions**

### Decision: Real-time Form Validation
**Date**: July 5, 2025
**Status**: Deprecated

**Reason**: Replaced by schema-based validation for better user experience.

**Original Decision**: Use OnValidate callbacks for real-time form validation feedback.

**Replacement**: Schema-based validation with submission-time error display.

---

## 📝 **Decision Impact Matrix**

| Decision | Development Speed | Scalability | Maintenance | User Experience |
|----------|------------------|-------------|-------------|-----------------|
| Schema Forms | ✅ Fast | ✅ Good | ✅ Easy | ✅ Excellent |
| JSON Storage | ✅ Fast | ⚠️ Limited | ✅ Easy | ✅ Good |
| GUID User IDs | ✅ Fast | ✅ Excellent | ✅ Easy | ✅ Good |
| Hybrid Auth | ⚠️ Medium | ✅ Good | ⚠️ Complex | ✅ Good |
| User Directories | ✅ Fast | ✅ Good | ✅ Easy | ✅ Excellent |

**Legend**: ✅ Positive Impact | ⚠️ Neutral/Mixed | ❌ Negative Impact

---
