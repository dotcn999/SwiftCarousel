# Options

Fine-tune a layout by returning values from ``CarouselOption``.

## How options work

Every option has a layout-specific default. Override only the values you need:

```swift
func carousel(_ carousel: CarouselView, valueForOption option: CarouselOption, withDefault value: CGFloat) -> CGFloat {
    switch option {
    case .spacing:
        return 0.8
    case .arc:
        return .pi
    case .fadeMin:
        return -2
    default:
        return value
    }
}
```

In SwiftUI, pass a dictionary to the `options` parameter:

```swift
Carousel(
    items: items,
    currentIndex: $index,
    type: .wheel,
    itemSize: CGSize(width: 120, height: 160),
    options: [.spacing: 0.9, .arc: .pi * 1.5, .count: 16]
) { item, _ in
    Text("\(item)")
}
```

## Option reference

| Option | Purpose |
| --- | --- |
| `wrap` | Enables infinite scrolling. |
| `showBackfaces` | Shows items whose back face is turned towards the viewer. |
| `offsetMultiplier` | Scales drag distance per point of translation. |
| `visibleItems` | Overrides the number of loaded item views. |
| `count` | Number of items used for circular layout calculations. |
| `arc` | Angular span of circular layouts, in radians. |
| `angle` | Angular spacing between items, in radians. |
| `radius` | Radius of circular layouts, in points. |
| `tilt` | Tilt of Cover Flow and Time Machine layouts. |
| `spacing` | Distance between items, measured in item widths. |
| `fadeMin` | Offset below which items begin to fade. |
| `fadeMax` | Offset above which items begin to fade. |
| `fadeRange` | Distance over which the fade completes. |
| `fadeMinAlpha` | Minimum opacity reached by a faded item. |

## Interaction options

- ``CarouselView/isScrollEnabled`` disables dragging without removing the carousel.
- ``CarouselView/isPagingEnabled`` snaps deceleration to one item at a time.
- ``CarouselView/autoscroll`` scrolls continuously, in items per second.
- ``CarouselView/bounces`` allows dragging slightly past the first or last item.
- ``CarouselView/scrollToItemBoundary`` aligns to an item after dragging stops.
- ``CarouselView/ignorePerpendicularSwipes`` prevents diagonal swipes from stealing gestures.
- ``CarouselView/centerItemWhenSelected`` centers an item when tapped.
