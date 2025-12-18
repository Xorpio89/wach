---
name: wach-design-system
description: Apply W.A.C.H. design system including dark mode colors, typography, and interaction patterns. Use when building UI, styling widgets, or creating new screens. Ensures consistent branding and user experience.
---

# W.A.C.H. Design System

## Color Palette (Dark Mode Default)

| Purpose | Color | Hex |
|---------|-------|-----|
| Background | Dark Grey | #121212 |
| Surface | Elevated Grey | #1E1E1E |
| Primary | Green (Growth) | #4CAF50 |
| Secondary | Orange (Energy) | #FF9800 |
| Text Primary | White | #FFFFFF |
| Text Secondary | Light Grey | #B0B0B0 |
| Error/Minus | Red | #F44336 |

## Typography

- **Headlines**: Bold, large for numbers/timers
- **Body**: Regular weight, readable
- **Numbers/Timers**: Monospace font family
- **Button Text**: Medium weight, uppercase optional

## Spacing System

- Base unit: 8dp
- Small: 4dp
- Medium: 8dp, 16dp
- Large: 24dp, 32dp
- XLarge: 48dp

## Interaction Patterns

| Gesture | Action |
|---------|--------|
| Long tap | Toggle Lock/Unlock mode |
| Tap | Execute action (Unlock mode) |
| Swipe | Navigate between pages |

## Touch Targets

- Minimum size: 48x48dp
- Recommended: 56x56dp for primary actions
- Large tiles for workout tracking

## Component Guidelines

### Cards/Tiles
```dart
Container(
  decoration: BoxDecoration(
    color: const Color(0xFF1E1E1E),
    borderRadius: BorderRadius.circular(12),
  ),
  padding: const EdgeInsets.all(16),
)
```

### Primary Button
```dart
ElevatedButton(
  style: ElevatedButton.styleFrom(
    backgroundColor: const Color(0xFF4CAF50),
    minimumSize: const Size(double.infinity, 48),
  ),
)
```

### Timer Display
```dart
Text(
  '02:30',
  style: TextStyle(
    fontFamily: 'monospace',
    fontSize: 48,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  ),
)
```

## Key Principles

1. **Minimal** - No unnecessary features
2. **Offline-first** - All data stored locally
3. **Touch-friendly** - Large interactive elements
4. **Dark mode** - Default and only theme
5. **Timer prominent** - Countdown is the USP
