# TDD Workflow - Test Driven Development

## Context
You are helping implement features using Test-Driven Development for a Flutter app with Riverpod state management and sembast database.

## Instructions

Follow the Red-Green-Refactor cycle:

### 1. RED - Write Failing Test First
```dart
// Example: Testing a new use case
test('should calculate progressive overload suggestion', () {
  // Arrange
  final lastSession = SessionModel(...);

  // Act
  final suggestion = calculateProgressiveOverload(lastSession);

  // Assert
  expect(suggestion.targetReps, greaterThan(lastSession.totalReps));
});
```

### 2. GREEN - Minimal Implementation
Write the minimum code to make the test pass. Don't over-engineer.

### 3. REFACTOR - Clean Up
- Remove duplication
- Improve naming
- Extract methods if needed
- Keep tests passing

## Test Categories

### Unit Tests (test/)
- Pure functions (utils, calculations)
- Model serialization
- Domain logic

### Widget Tests (test/)
- Individual widgets
- User interactions
- State changes

### Integration Tests (integration_test/)
- Full user flows
- Database operations
- Navigation

## Commands

Run tests:
```bash
flutter test                           # All tests
flutter test --coverage               # With coverage
flutter test test/path/to/test.dart   # Specific test
```

## When to Use This Command

Use `/tdd` when:
- Implementing a new feature
- Fixing a bug (write test to reproduce first)
- Adding new business logic

$ARGUMENTS
