# 📖 Knowledge Base - Multi-User Health Tracker

> **Purpose**: Centralized repository of project knowledge, research findings, and technical references for maintaining continuity across development sessions.

---
## ALL CMDLET HELP DOCS
- [PSModule 'Universal' function help docs](../universal-docs/cmdlets/)

## 📋 **Quick Reference Index**

### **PowerShell Universal**
- [Forms & Validation](#powershell-universal-forms--validation)
- [Authentication Systems](#authentication-systems)
- [Dashboard Components](#dashboard-components)
- [API & Endpoints](#api--endpoints)

### **Project Architecture**
- [Data Storage Strategy](#data-storage-strategy)
- [User Management](#user-management)
- [Security Considerations](#security-considerations)
- [Scalability Planning](#scalability-planning)

### **Health Tracking Domain**
- [Health Data Models](#health-data-models)
- [Medical Standards](#medical-standards)
- [Privacy & Compliance](#privacy--compliance)

### **Development Resources**
- [External Libraries](#external-libraries)
- [Useful PowerShell Modules](#useful-powershell-modules)
- [Documentation Links](#documentation-links)

---

## 🎨 **PowerShell Universal Forms & Validation**

### **Schema Form Best Practices**
```powershell
# Discovered: Schema forms provide better UX than OnValidate
# - No annoying live validation interruptions
# - Built-in error display handling
# - Consistent styling across all forms

# Schema validation syntax:
@{
    type = "string"
    title = "Display Name"
    minLength = 1          # Minimum character length
    maxLength = 100        # Maximum character length
    format = "email"       # Built-in formats: email, date, time, password
    pattern = "regex"      # Custom regex validation
    enum = @()            # Dropdown options (values)
    enumNames = @()       # Dropdown options (display names)
    const = $true         # Must equal specific value (for checkboxes)
    default = "value"     # Default value
}
```

### **Form Validation Gotchas**
- ❌ **`-Required` parameter doesn't exist** on PSU form controls
- ✅ **Use `required: @()` array in schema** for required field validation
- ❌ **OnValidate causes poor UX** with constant interruption
- ✅ **Schema validation shows errors on submit** - better experience
- ⚠️ **Password confirmation** must be handled in OnSubmit logic

### **Form Styling Patterns**
```powershell
# Responsive grid for mobile-friendly forms
New-UDGrid -Container -Content {
    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
        # Left column
    }
    New-UDGrid -Item -ExtraSmallSize 12 -SmallSize 6 -Content {
        # Right column
    }
}

# Consistent button styling
New-UDButton -Text "Submit" -ButtonType submit -FullWidth -Size large
```

---

## 🔐 **Authentication Systems**

### **PowerShell Universal Authentication Options**

1. **Local Accounts** (Chosen for MVP)
   - Built into PSU
   - Easy user management
   - Session handling included
   - Limited to basic username/password

2. **Forms Authentication** (Chosen for MVP)
   - Custom login forms
   - Integration with external user stores
   - Full control over authentication flow
   - Can combine with Local Accounts

3. **Enterprise Options** (Future)
   - Azure AD / Active Directory
   - OAuth providers (Google, GitHub, etc.)
   - SAML integration
   - JWT token authentication

### **Hybrid Approach Decision**
```powershell
# Decided approach: PSU Local Accounts + Custom Registration
# 1. Custom registration form creates user profile JSON
# 2. Creates corresponding PSU local account
# 3. PSU handles session management
# 4. Custom profile data stored separately

# Benefits:
# - Leverage PSU's session management
# - Custom user profile data
# - Easy to extend later
# - Security handled by PSU framework
```

### **Password Security Standards**
- Minimum 8 characters
- Must include: uppercase, lowercase, number, special character
- Use PSU's built-in password hashing
- Store hashed passwords only
- Implement account lockout after failed attempts

---

## 🗄️ **Data Storage Strategy**

### **Phase 1: JSON File Storage**
```powershell
# Directory structure:
/data/users/{userId}/
├── profile.json          # User account information
├── preferences.json       # User settings and preferences
├── health-data/
│   ├── entries.json      # Health tracking entries
│   ├── medications.json  # User's medication list
│   └── goals.json        # Health goals and targets
└── attachments/          # User-uploaded files
    ├── images/
    └── documents/

# User ID: GUID format for security
# Example: 550e8400-e29b-41d4-a716-446655440000
```

### **Data Isolation Benefits**
- **Privacy**: Complete separation between users
- **Backup**: Easy per-user backup and restore
- **Deletion**: Simple user data removal
- **Migration**: Straightforward database migration path
- **Debugging**: Easy to inspect individual user data

### **File Management Functions Needed**
```powershell
# Core functions to implement:
function New-UserDirectory { }          # Create user folder structure
function Test-UserEmailExists { }      # Check email uniqueness
function Get-UserProfile { }           # Load user profile data
function Set-UserProfile { }           # Save user profile data
function Remove-UserData { }           # Clean user deletion
function Export-UserData { }           # GDPR compliance export
```

---

## 👤 **User Management**

### **User Profile Data Model**
```json
{
  "UserId": "guid",
  "Email": "string (unique)",
  "FirstName": "string",
  "LastName": "string", 
  "DisplayName": "string",
  "Timezone": "string",
  "CreatedDate": "datetime",
  "LastLoginDate": "datetime",
  "IsActive": "boolean",
  "EmailVerified": "boolean",
  "AcceptedTermsDate": "datetime",
  "HealthProfile": {
    "DateOfBirth": "date (optional)",
    "PrimaryConditions": ["array"],
    "MedicationAllergies": ["array"],
    "EmergencyContact": { "object" }
  }
}
```

### **User Preferences Data Model**
```json
{
  "Theme": "string",
  "Language": "string", 
  "DateFormat": "string",
  "TimeFormat": "string",
  "TemperatureUnit": "string",
  "WeightUnit": "string",
  "NotificationSettings": {
    "EmailNotifications": "boolean",
    "MedicationReminders": "boolean", 
    "HealthCheckReminders": "boolean"
  },
  "PrivacySettings": {
    "AllowDataCollection": "boolean",
    "AllowAnonymousAnalytics": "boolean"
  }
}
```

### **Registration Workflow**
1. Validate form input (schema validation)
2. Check email uniqueness
3. Generate GUID for user ID
4. Hash password securely
5. Create user directory structure
6. Save profile.json and preferences.json
7. Create PSU local account
8. Send welcome email (future)
9. Redirect to onboarding (future)

---

## 🏥 **Health Data Models**

### **Health Entry Structure**
```json
{
  "id": "guid",
  "userId": "guid", 
  "timestamp": "datetime",
  "entryDate": "date",
  "entryTime": "time",
  "painLevel": "number (0-10)",
  "painLocations": ["array of strings"],
  "medications": [
    {
      "name": "string",
      "dosage": "string", 
      "timeTaken": "time",
      "effectiveness": "number (1-5)"
    }
  ],
  "activities": [
    {
      "type": "string",
      "duration": "number (minutes)",
      "intensity": "string (low/moderate/high)",
      "notes": "string"
    }
  ],
  "mood": "number (1-5)",
  "sleepHours": "number",
  "notes": "string",
  "attachments": ["array"]
}
```

### **Pain Location Standards**
```powershell
# Standardized pain location options
$PainLocations = @(
    "Head/Headache", "Neck", "Upper Back", "Lower Back", 
    "Left Shoulder", "Right Shoulder", "Left Arm", "Right Arm",
    "Left Hand", "Right Hand", "Chest", "Abdomen",
    "Left Hip", "Right Hip", "Left Leg", "Right Leg", 
    "Left Knee", "Right Knee", "Left Foot", "Right Foot",
    "Joints (General)", "Muscles (General)", "Other"
)
```

### **Medication Management**
```powershell
# Common medication categories for health tracking
$MedicationCategories = @(
    "Pain Relief", "Anti-inflammatory", "Muscle Relaxer",
    "Antidepressant", "Anxiety", "Sleep Aid", "Blood Pressure",
    "Diabetes", "Heart", "Thyroid", "Vitamin/Supplement", "Other"
)
```

---

## 🔒 **Security Considerations**

### **Data Protection Standards**
- **Encryption at Rest**: Plan for sensitive data encryption
- **Encryption in Transit**: HTTPS only for all communication
- **Access Control**: User data isolation enforced at application level
- **Audit Logging**: Track all data access and modifications
- **Data Retention**: Implement data deletion policies
- **Backup Security**: Encrypted backups with access controls

### **Authentication Security**
- **Password Policies**: Enforce strong password requirements
- **Session Management**: Use PSU's built-in secure session handling
- **Failed Login Protection**: Implement account lockout mechanisms
- **Password Reset**: Secure password reset via email verification
- **Multi-Factor Authentication**: Plan for future implementation

### **Privacy Compliance Considerations**
- **HIPAA**: Health data protection requirements
- **GDPR**: European privacy law compliance
- **CCPA**: California privacy law compliance
- **Data Export**: User right to data portability
- **Data Deletion**: User right to be forgotten
- **Consent Management**: Track user consent for data processing

---

## 📚 **Documentation Links**

### **PowerShell Universal**
- **Official Docs**: https://docs.powershelluniversal.com/
- **Cmdlet Reference**: https://github.com/ironmansoftware/universal-docs/tree/v5/cmdlets
- **Form Examples**: https://docs.powershelluniversal.com/userinterfaces/forms
- **Authentication Guide**: https://docs.powershelluniversal.com/config/security

### **PowerShell Modules**
- **PSWriteHTML**: HTML report generation
- **ImportExcel**: Excel file manipulation  
- **PSSQLite**: SQLite database operations
- **PSWriteWord**: Word document generation
- **Pode**: Alternative web framework (research)

### **Health Standards**
- **HL7 FHIR**: Healthcare data exchange standards
- **ICD-10**: International disease classification
- **SNOMED CT**: Clinical terminology standards
- **HIPAA**: Healthcare privacy regulations

### **UI/UX Resources**
- **Material-UI**: React component library (PSU uses)
- **Responsive Design**: Mobile-first design principles
- **Accessibility**: WCAG 2.1 compliance guidelines
- **Color Theory**: Healthcare app color psychology

---

## 🛠️ **Development Tools & Environment**

### **PowerShell Universal Environment**
```powershell
# Development environment setup
$PSUVersion = "5.x"  # Current version being used
$PowerShellVersion = "7.x"  # PowerShell version

# Key directories:
$ConfigPath = "/fusion-conf"          # PSU configuration
$DataPath = "/data"                   # Application data
$ModulesPath = "/Modules"             # Custom PowerShell modules
$DashboardsPath = "/dashboards"       # Dashboard files
```

### **Version Control Strategy**
- Git repository structure
- .gitignore for sensitive data
- Branch strategy for development
- Deployment automation planning

### **Testing Approach**
- Unit tests for PowerShell functions
- Integration tests for user workflows
- Manual testing procedures
- Performance testing for scale

---

## 💡 **Lessons Learned**

### **PowerShell Universal Insights**
1. **Schema forms > OnValidate** for better user experience
2. **Built-in validation** is more reliable than custom validation
3. **PSU session management** handles security well
4. **Material-UI styling** works well with PSU components
5. **Mobile responsiveness** requires careful grid planning

### **Development Workflow Insights**
1. **Plan data models first** before building UI
2. **Start with JSON**, migrate to database later
3. **Security by design** from the beginning
4. **User experience** should drive technical decisions
5. **Documentation** is crucial for project continuity

### **Healthcare Domain Insights**
1. **Privacy is paramount** - design with HIPAA in mind
2. **User data export** is required for compliance
3. **Audit trails** are essential for healthcare apps
4. **Mobile-first** is critical for health tracking
5. **Medication management** requires careful validation

---

## 🎯 **Quick Decision Reference**

| Question | Decision | Rationale |
|----------|----------|-----------|
| Form validation approach? | Schema-based | Better UX, less code |
| Initial data storage? | JSON files | Rapid development, easy migration |
| User ID format? | GUIDs | Security, uniqueness, future-proof |
| Authentication method? | PSU Local + Custom | Leverage PSU, custom profiles |
| Data isolation? | User directories | Privacy, backup, compliance |
| Password requirements? | 8+ chars, mixed case, numbers, symbols | Security best practices |
| Default timezone? | Mountain Time | Project location preference |
| Mobile strategy? | Responsive design | Universal access, cost-effective |

---

## 📝 **Future Research Topics**

### **Short-term (Next 30 days)**
- Email service integration options (SendGrid, AWS SES)
- Password reset implementation patterns
- User onboarding workflow design
- Mobile responsive design best practices

### **Medium-term (3-6 months)**
- Database migration strategy (PostgreSQL vs SQLite)
- Real-time notifications implementation
- Progressive Web App features
- Healthcare provider portal design

### **Long-term (6+ months)**
- HIPAA compliance implementation
- Machine learning integration
- API development strategy
- Multi-tenant architecture scaling

---

This knowledge base should be updated regularly as new insights are discovered during development sessions.
