# ``SwiftCarousel``

A Swift 6 rewrite of iCarousel 1.8.3: 3D carousel layouts for UIKit and SwiftUI, distributed with Swift Package Manager.

## Overview

SwiftCarousel provides a UIKit core, ``CarouselView``, and a SwiftUI wrapper, ``Carousel``. Both share the same layouts, options, view recycling and scroll physics as the original iCarousel.

The package has no Objective-C sources and no third-party dependencies. It requires iOS 16 or later and is built with the Swift 6 toolchain.

```swift
import SwiftCarousel
import SwiftUI

struct ContentView: View {
    @State private var index = 0

    var body: some View {
        Carousel(
            items: Array(0..<20),
            currentIndex: $index,
            type: .coverFlow2,
            itemSize: CGSize(width: 230, height: 300)
        ) { item, _ in
            Text("\(item)")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.thinMaterial)
        }
    }
}
```

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Layouts>
- <doc:Options>
- <doc:MigrationFromICarousel>

### UIKit

- ``CarouselView``
- ``CarouselDataSource``
- ``CarouselDelegate``

### SwiftUI

- ``Carousel``

### Configuration

- ``CarouselType``
- ``CarouselOption``
