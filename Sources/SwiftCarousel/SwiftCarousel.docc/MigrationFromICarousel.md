# Migrating from iCarousel

SwiftCarousel keeps the original layouts and behaviour, but adopts Swift naming and concurrency.

## Type mapping

| iCarousel | SwiftCarousel |
| --- | --- |
| `iCarousel` | ``CarouselView`` |
| `iCarouselType` | ``CarouselType`` |
| `iCarouselOption` | ``CarouselOption`` |
| `iCarouselDataSource` | ``CarouselDataSource`` |
| `iCarouselDelegate` | ``CarouselDelegate`` |

## Method mapping

| iCarousel | SwiftCarousel |
| --- | --- |
| `numberOfItemsInCarousel:` | `numberOfItems(in:)` |
| `carousel:viewForItemAtIndex:reusingView:` | `carousel(_:viewForItemAt:reusing:)` |
| `carousel:didSelectItemAtIndex:` | `carousel(_:didSelectItemAt:)` |
| `carouselCurrentItemIndexDidChange:` | `carouselCurrentItemIndexDidChange(_:)` |
| `scrollToItemAtIndex:animated:` | `scrollToItem(at:animated:)` |
| `reloadItemAtIndex:animated:` | `reloadItem(at:animated:)` |

Enum raw values match the originals, so persisted layout indexes keep working:

```swift
let type = CarouselType(rawValue: storedValue) ?? .linear
```

## Behavioural differences

- **Swift concurrency.** Protocols and views are main-actor isolated. Mutate the carousel from the main thread.
- **No NSCoding archive compatibility.** Storyboards and nibs work through `init?(coder:)`, but archived `iCarousel` state is not migrated.
- **No macOS target.** The original supported AppKit; this package targets UIKit only.
- **No CocoaPods or single-file Objective-C distribution.** Use Swift Package Manager.

## Attribution

The layout math and scroll physics are ported from iCarousel 1.8.3 by Nick Lockwood. The original project is available at [nicklockwood/iCarousel](https://github.com/nicklockwood/iCarousel) under the zlib license.
