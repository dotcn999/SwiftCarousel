// swift-tools-version: 6.0
// Swift port of iCarousel 1.8.3 (https://github.com/nicklockwood/iCarousel, zlib license).

import PackageDescription

let package = Package(
    name: "SwiftCarousel",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(name: "SwiftCarousel", targets: ["SwiftCarousel"])
    ],
    targets: [
        .target(
            name: "SwiftCarousel",
            path: "Sources/SwiftCarousel"
        ),
        .testTarget(
            name: "SwiftCarouselTests",
            dependencies: ["SwiftCarousel"],
            path: "Tests/SwiftCarouselTests"
        )
    ]
)
