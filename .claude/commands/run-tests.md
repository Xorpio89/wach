# Run Tests

## Context
Run Flutter tests for the W.A.C.H. project.

## Instructions

1. Navigate to the Flutter project directory
2. Run the appropriate test command based on arguments

## Test Commands

### All Tests
```bash
cd wach_flutter && flutter test
```

### With Coverage
```bash
cd wach_flutter && flutter test --coverage
```

### Specific Test File
```bash
cd wach_flutter && flutter test test/path/to/test.dart
```

### Unit Tests Only
```bash
cd wach_flutter && flutter test test/core/ test/features/*/data/
```

### Widget Tests Only
```bash
cd wach_flutter && flutter test test/features/*/presentation/
```

## Output

After running tests, report:
- Number of tests passed/failed
- Any failures with details
- Coverage summary if --coverage was used

$ARGUMENTS
