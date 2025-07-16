# Health Entry Schema Documentation - v2.0 (Unified)

## Overview
The unified health entry schema consolidates multiple health types into single logical submissions using composite keys for unique identification. This eliminates data duplication and provides a more natural data structure that matches how users submit health information.

## Schema Version: 2.0 (Unified Structure)
**Implementation Date**: January 14, 2025  
**Last Updated**: July 15, 2025

## Entry Structure

### Root Entry Format
```json
{
  "entry_id": "yyMMddHHmm",
  "user_email": "user@example.com", 
  "date": "YYYY-MM-DD",
  "time": "HH:mm",
  "entry_types": ["type1", "type2", ...],
  "data": {
    "type1": { /* type-specific data */ },
    "type2": { /* type-specific data */ }
  },
  "notes": "Combined notes describing all activities"
}
```

### Composite Key Format (entry_id)
- **Format**: `yyMMddHHmm`
- **Example**: `2507151430` = July 15, 2025 at 14:30
- **Benefits**: Natural sorting, timezone-aware, minute precision, collision prevention

## Health Type Schemas

### 1. Mood
```json
{
  "mood_level": 1-5,
  "mood_note": "string"
}
```
**Scale**: 1=Awful, 2=Bad, 3=Meh, 4=Good, 5=Rad

### 2. Vitals  
```json
{
  "blood_pressure": "120/80",
  "heart_rate": 60-100,
  "oxygen_saturation": 95-100,
  "temperature": 97.0-99.5
}
```
**Note**: Blood pressure stored as string format "systolic/diastolic"

### 3. Medication
```json
{
  "medication_name": "string",
  "dosage": "string"
}
```

### 4. Activity
```json
{
  "activity_name": "string", 
  "duration_minutes": 15-90,
  "note": "string"
}
```

### 5. Pain
```json
{
  "location": "string",
  "severity": 1-10,
  "note": "string"
}
```

### 6. Weight
```json
{
  "weight_lbs": 120.0-220.0,
  "weight_kg": "auto-calculated"
}
```
**Note**: weight_kg automatically calculated using conversion factor 0.453592

### 7. Sleep
```json
{
  "sleep_hours": 5.0-10.0
}
```

## Complete Example Entry
```json
{
  "entry_id": "2507151430",
  "user_email": "user@example.com",
  "date": "2025-07-15", 
  "time": "14:30",
  "entry_types": ["vitals", "mood", "activity"],
  "data": {
    "vitals": {
      "blood_pressure": "125/82",
      "heart_rate": 75,
      "oxygen_saturation": 98,
      "temperature": 98.6
    },
    "mood": {
      "mood_level": 4,
      "mood_note": "Feeling energized after workout"
    },
    "activity": {
      "activity_name": "Jogging",
      "duration_minutes": 30,
      "note": "Beautiful morning run in the park"
    }
  },
  "notes": "Vital signs check, Mood: Good 🙂, Jogging session"
}
```

## Key Benefits

### 1. Eliminated Data Duplication
- Single metadata set for related health submissions
- No repeated user_email, date, time across related entries

### 2. Logical Data Grouping  
- Health data submitted together stays together
- Matches natural user behavior patterns

### 3. Efficient Storage & Queries
- Reduced storage overhead from eliminated duplication
- Single query retrieves all related health data for a submission

### 4. Composite Key Advantages
- Natural chronological sorting
- Timezone-aware timestamps
- Minute-level precision
- Collision prevention across users

## Multi-User Support

### User Isolation
- All functions require `EntriesPath` parameter for user-specific data access
- No shared data structures between users
- Base64-encoded user directories for filesystem safety

### Sample Data Generation
- `New-SampleHealthEntries` function generates realistic unified entries
- 1-4 health types per entry (simulating real user behavior)
- Composite key generation with proper time distribution

## Migration Notes

### From Legacy Schema (v1.0)
- **Old Format**: Separate entries per health type with auto-incrementing IDs
- **New Format**: Unified entries with composite keys
- **Migration**: Not required for development environment - fresh start recommended

### Backward Compatibility
- Legacy data can coexist during transition period
- Dashboard code needs updates to handle unified structure
- Forms need updates for multi-type submission support

## Implementation Status

✅ **Complete**:
- Unified schema design
- Composite key system
- Sample data generator
- Multi-user functions
- Comprehensive test suite (82 tests, 100% pass rate)

🔄 **In Progress**:
- Dashboard integration
- Form submission updates

⏳ **Pending**:
- Complete system integration testing
- Performance optimization for large datasets

## File Locations
- **Schema Documentation**: `/fusion-conf/Modules/fusion/entries_schema_v2.json`
- **Sample Generator**: `/fusion-conf/Modules/fusion/fusion.psm1` (New-SampleHealthEntries function)
- **Test Suite**: `/fusion-conf/Modules/fusion/fusion.Tests.ps1`
- **Implementation Details**: `/fusion-conf/project-status/UNIFIED-SCHEMA-IMPLEMENTATION.md`

## Schema Validation
All entries are validated through comprehensive Pester tests covering:
- Composite key format validation
- Required field presence
- Data type constraints  
- Multi-user isolation
- Edge cases and error handling

**Test Coverage**: 82 tests with 100% success rate
**Last Validation**: July 15, 2025
