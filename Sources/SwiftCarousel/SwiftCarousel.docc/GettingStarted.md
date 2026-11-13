# Getting started

Add the package, create a carousel, and supply item views.

## Add the package

In Xcode, choose **File > Add Package Dependencies…** and enter:

```
https://github.com/dotcn999/SwiftCarousel.git
```

Or add the dependency to `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/dotcn999/SwiftCarousel.git", from: "1.0.0")
]
```

## Use SwiftUI

``Carousel`` takes an array of items, an index binding and a view builder:

```swift
import SwiftCarousel
import SwiftUI

struct ContentView: View {
    @State private var selection = 0
    private let items = Array(0..<20)

    var body: some View {
        Carousel(
            items: items,
            currentIndex: $selection,
            type: .cylinder,
            itemSize: CGSize(width: 220, height: 300),
            options: [.wrap: 1]
        ) { item, _ in
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(hue: Double(item) / 20, saturation: 0.6, brightness: 0.9))
                .overlay(Text("\(item)").font(.largeTitle.bold()))
        }
    }
}
```

The binding stays in sync when the user drags, taps or when you change it programmatically.

## Use UIKit

Set a data source and, optionally, a delegate. Both are weak references, so keep the data source alive for as long as the carousel is visible.

```swift
final class ViewController: UIViewController, CarouselDataSource {
    let carousel = CarouselView(frame: .zero)
    let items = Array(0..<20)

    override func viewDidLoad() {
        super.viewDidLoad()

        carousel.translatesAutoresizingMaskIntoConstraints = false
        carousel.dataSource = self
        carousel.type = .coverFlow2
        view.addSubview(carousel)

        NSLayoutConstraint.activate([
            carousel.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            carousel.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            carousel.topAnchor.constraint(equalTo: view.topAnchor),
            carousel.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    func numberOfItems(in carousel: CarouselView) -> Int {
        items.count
    }

    func carousel(_ carousel: CarouselView, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
        let label = view as? UILabel ?? UILabel()
        label.text = "\(items[index])"
        label.textAlignment = .center
        label.frame = CGRect(x: 0, y: 0, width: 220, height: 300)
        return label
    }
}
```

## Next steps

- Choose a layout in <doc:Layouts>.
- Tune spacing, arc, tilt and fade behavior in <doc:Options>.
- Compare against the original API in <doc:MigrationFromICarousel>.
