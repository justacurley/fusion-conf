# Multi-User Fusion Module Migration

## Overview
Updated the fusion module to support multi-user architecture by making `EntriesPath` a required parameter for all functions instead of relying on global paths.

## Key Changes Made

### 1. **Global Path Logic Updated**
- **Before**: Hard-coded global paths for single-user usage
- **After**: Added comments indicating legacy support, new functions require explicit paths

### 2. **Function Parameter Updates**

#### `Save-ConvertedEntry`
- **Before**: `[string]$EntriesPath = $global:EntriesPath` (optional with global fallback)
- **After**: `[string]$EntriesPath` (required parameter with validation)

#### `Get-CachedEntriesData`
- **Before**: Used PSU variables and global fallbacks to determine path
- **After**: `[string]$EntriesPath` (required parameter)
- **Benefit**: Direct path specification, better for multi-user caching

#### `Remove-TimeEntry`
- **Before**: `[string]$EntriesPath` (optional with global/PSU variable fallback)
- **After**: `[string]$EntriesPath` (required parameter with validation)

### 3. **New Helper Function Added**

#### `Get-UserEntriesPath`
```powershell
$entriesPath = Get-UserEntriesPath -UserEmail "user@example.com"
# Returns: /home/alex/src/fusion-local/data/users/dXNlckBleGFtcGxlLmNvbQ/health-data/entries.json
```

**Features**:
- Automatically encodes email addresses using Base64 for safe filesystem usage
- Environment-aware base path detection (local vs. production)
- Input validation for email format
- Clear error handling

### 4. **Enhanced Validation**
All functions now include:
- Path validation to ensure parent directories exist
- Better error messages for multi-user scenarios
- Consistent parameter naming and validation

## Migration Benefits

### **Multi-User Support**
- Each user gets their own isolated entries.json file
- No shared global state between users
- Thread-safe operation in multi-user environments

### **Explicit Dependencies**
- Functions now clearly declare their path requirements
- Easier testing with specific test data paths
- Better separation of concerns

### **Backward Compatibility**
- Global variables still exist for legacy code
- Gradual migration path available
- Existing single-user installations continue to work

## Usage Examples

### **Old Usage (Single-User)**
```powershell
# Functions relied on global paths
$result = Save-ConvertedEntry -ConvertedEntry $entry
$entries = Get-CachedEntriesData
Remove-TimeEntry -Date "0701" -Time "1430"
```

### **New Usage (Multi-User)**
```powershell
# Generate user-specific path
$userEntriesPath = Get-UserEntriesPath -UserEmail "alex@example.com"

# Pass explicit paths to all functions
$result = Save-ConvertedEntry -ConvertedEntry $entry -EntriesPath $userEntriesPath
$entries = Get-CachedEntriesData -EntriesPath $userEntriesPath
Remove-TimeEntry -Date "0701" -Time "1430" -EntriesPath $userEntriesPath
```

### **Dashboard Integration Example**
```powershell
# In dashboard code
$CurrentUserEmail = $Session:User.Identity.Name
$UserEntriesPath = Get-UserEntriesPath -UserEmail $CurrentUserEmail

# All fusion functions now work with user-specific data
$userEntries = Get-CachedEntriesData -EntriesPath $UserEntriesPath
```

## Path Structure

### **User Data Organization**
```
/home/alex/src/fusion-local/data/users/
├── dXNlckBleGFtcGxlLmNvbQ/           # Base64 encoded user@example.com
│   └── health-data/
│       └── entries.json
├── YWxleEBkb21haW4uY29t/             # Base64 encoded alex@domain.com
│   └── health-data/
│       └── entries.json
└── ...
```

### **Benefits of Base64 Encoding**
- **Safe Characters**: No special characters that could break filesystems
- **Reversible**: Can decode back to original email if needed
- **Consistent Length**: Predictable directory naming
- **Cross-Platform**: Works on Windows, Linux, macOS

## Implementation Status

✅ **Complete**: Core function parameter updates
✅ **Complete**: Path validation and error handling
✅ **Complete**: Helper function for user path generation
✅ **Complete**: Documentation and examples
⏳ **Next**: Update dashboard components to use new parameter structure
⏳ **Next**: Update any existing scripts that call these functions

## Breaking Changes

### **Functions Requiring Updates**
Any code calling these functions must now provide the `EntriesPath` parameter:
- `Save-ConvertedEntry`
- `Get-CachedEntriesData`
- `Remove-TimeEntry`

### **Migration Script Example**
```powershell
# Before
$entries = Get-CachedEntriesData

# After
$userEmail = Get-CurrentUserEmail  # Your function to get current user
$entriesPath = Get-UserEntriesPath -UserEmail $userEmail
$entries = Get-CachedEntriesData -EntriesPath $entriesPath
```

The fusion module is now ready for true multi-user operation with proper data isolation and explicit path management!
