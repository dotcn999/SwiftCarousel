# Layouts

Pick one of the twelve layouts with ``CarouselView/type`` or the SwiftUI `type` parameter.

## Built-in layouts

| Type | Description | Wraps by default |
| --- | --- | --- |
| `linear` | Flat horizontal or vertical strip. | No |
| `rotary` | Items follow a shallow horizontal arc. | Yes |
| `invertedRotary` | Rotary arc bending the other way. | Yes |
| `cylinder` | Items rotate around a vertical cylinder axis. | Yes |
| `invertedCylinder` | Cylinder with reversed rotation. | Yes |
| `wheel` | Items are placed on a circle around the center. | Yes |
| `invertedWheel` | Wheel moving in the opposite direction. | Yes |
| `coverFlow` | Classic tilted album covers. | No |
| `coverFlow2` | Cover Flow with a toggle animation between items. | No |
| `timeMachine` | Items recede into the distance like a stack of cards. | No |
| `invertedTimeMachine` | Time Machine with reversed depth. | No |
| `custom` | Your own `CATransform3D`, supplied by the delegate. | No |

## Wrap and orientation

Circular layouts enable ``CarouselView/isWrapEnabled`` automatically. Override it through the ``CarouselOption/wrap`` option:

```swift
carousel.delegate = self // implement carousel(_:valueForOption:withDefault:)
```

```swift
func carousel(_ carousel: CarouselView, valueForOption option: CarouselOption, withDefault value: CGFloat) -> CGFloat {
    if option == .wrap { return 0 }
    return value
}
```

Set ``CarouselView/isVertical`` to rotate the carousel ninety degrees. The same layouts and drag physics apply to the vertical axis.

## Custom layouts

Use ``CarouselType/custom`` together with ``CarouselDelegate/carousel(_:itemTransformForOffset:baseTransform:)`` or the SwiftUI `customTransform` closure. The offset is measured in item widths from the current position:

```swift
func carousel(
    _ carousel: CarouselView,
    itemTransformForOffset offset: CGFloat,
    baseTransform transform: CATransform3D
) -> CATransform3D {
    CATransform3DTranslate(transform, offset * carousel.itemWidth, 0, 0)
}
```

The base transform already contains the perspective and viewpoint offset, so start from it rather than from `CATransform3DIdentity`.

## View sizing

The first item view determines ``CarouselView/itemWidth``. To use a different width, implement ``CarouselDelegate/carouselItemWidth(_:)`` or set an explicit frame on item views.
