# Changelog

## 1.0.0 — 2026-11-13

Initial public release.

- Swift 6 rewrite of iCarousel 1.8.3 with no Objective-C or CocoaPods dependencies
- UIKit core (`CarouselView`) with all 12 original layouts and CATransform3D math
- SwiftUI wrapper (`Carousel`) driven by an array of items and an index binding
- View reuse, placeholders, wrapping, paging, autoscroll, drag/deceleration physics
- Insert, remove and reload item animations
- SwiftPM distribution, iOS 16+, unit tests and a demo app with UI tests
