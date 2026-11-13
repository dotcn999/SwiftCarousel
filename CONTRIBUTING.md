# Contributing

Thanks for helping improve SwiftCarousel.

## Requirements

- macOS with Xcode 16 or later
- iOS 16+ simulator
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) only if you change `Demo/project.yml`

## Project layout

| Path | Contents |
| --- | --- |
| `Sources/SwiftCarousel` | UIKit core, SwiftUI wrapper and DocC catalog |
| `Tests/SwiftCarouselTests` | Unit tests for layouts, physics and gestures |
| `Demo` | SwiftUI demo app and UI tests |

## Build and test

Package unit tests:

```bash
xcodebuild test -scheme SwiftCarousel \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Demo app and UI tests:

```bash
cd Demo
xcodebuild test -project SwiftCarouselDemo.xcodeproj -scheme SwiftCarouselDemo \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Replace the simulator name if it is not installed on your machine. Run the unit tests before opening a pull request.

## Code style

- Use Swift 6 language mode and keep the package free of Objective-C.
- Mark carousel-facing types and tests with `@MainActor`.
- Keep layout math aligned with iCarousel 1.8.3 unless the change is intentional; explain differences in the pull request.
- Add or update tests when behaviour changes.
- Prefer small, focused commits with an imperative subject line.

## Adding a layout

1. Add a case to `CarouselType` without renumbering existing raw values.
2. Implement its transform in `CarouselView+Layout.swift`.
3. Update `isCircular`, the visible-item calculation and DocC articles if needed.
4. Add a layout test in `CarouselLayoutTests.swift`.
5. Add the layout to the demo picker and screenshots when practical.

## Reporting bugs

Include the layout type, item count, relevant option values, iOS version and a screen recording or screenshots when possible. The demo app accepts launch arguments to reproduce a specific state:

```bash
-demoType 8 -demoIndex 4
```

## License

By contributing, you agree that your changes are licensed under the zlib license in [LICENSE.md](LICENSE.md).
