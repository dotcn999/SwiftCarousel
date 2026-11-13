//
//  CarouselView+Layout.swift
//  SwiftCarousel
//
//  Ported from iCarousel 1.8.3 by Nick Lockwood.
//  https://github.com/nicklockwood/iCarousel — zlib license.
//

import QuartzCore
import UIKit

extension CarouselView {

    // MARK: - Options

    func optionValue(_ option: CarouselOption, default defaultValue: CGFloat) -> CGFloat {
        delegate?.carousel(self, valueForOption: option, withDefault: defaultValue) ?? defaultValue
    }

    func boolOption(_ option: CarouselOption, default defaultValue: Bool) -> Bool {
        optionValue(option, default: defaultValue ? 1 : 0) >= 0.5
    }

    // MARK: - Positioning

    /// The offset of an item relative to the current scroll position.
    public func offsetForItem(at index: Int) -> CGFloat {
        var offset = CGFloat(index) - storedScrollOffset

        if isWrapEnabled {
            if offset > CGFloat(numberOfItems) / 2 {
                offset -= CGFloat(numberOfItems)
            } else if offset < -CGFloat(numberOfItems) / 2 {
                offset += CGFloat(numberOfItems)
            }
        }

        return offset
    }

    func clampedIndex(_ index: Int) -> Int {
        guard numberOfItems > 0 else { return -1 }

        if isWrapEnabled {
            var wrapped = index % numberOfItems
            if wrapped < 0 {
                wrapped += numberOfItems
            }
            return wrapped
        }

        return min(max(0, index), numberOfItems - 1)
    }

    func clampedOffset(_ offset: CGFloat) -> CGFloat {
        guard numberOfItems > 0 else { return -1 }

        if isWrapEnabled {
            let count = CGFloat(numberOfItems)
            return offset - floor(offset / count) * count
        }

        return min(max(0, offset), CGFloat(numberOfItems - 1))
    }

    func minScrollDistance(fromIndex: Int, toIndex: Int) -> Int {
        let directDistance = toIndex - fromIndex
        guard isWrapEnabled, numberOfItems > 0 else { return directDistance }

        var wrappedDistance = min(toIndex, fromIndex) + numberOfItems - max(toIndex, fromIndex)
        if fromIndex < toIndex {
            wrappedDistance = -wrappedDistance
        }
        return abs(directDistance) <= abs(wrappedDistance) ? directDistance : wrappedDistance
    }

    func minScrollDistance(fromOffset: CGFloat, toOffset: CGFloat) -> CGFloat {
        let directDistance = toOffset - fromOffset
        guard isWrapEnabled, numberOfItems > 0 else { return directDistance }

        var wrappedDistance = min(toOffset, fromOffset) + CGFloat(numberOfItems) - max(toOffset, fromOffset)
        if fromOffset < toOffset {
            wrappedDistance = -wrappedDistance
        }
        return abs(directDistance) <= abs(wrappedDistance) ? directDistance : wrappedDistance
    }

    // MARK: - Layout

    func layoutItemViews() {
        guard dataSource != nil else { return }

        isWrapEnabled = type.isCircular
        isWrapEnabled = boolOption(.wrap, default: isWrapEnabled)
        numberOfPlaceholdersToShow = isWrapEnabled ? 0 : numberOfPlaceholders

        updateItemWidth()
        updateNumberOfVisibleItems()

        previousScrollOffset = storedScrollOffset
        offsetMultiplier = optionValue(.offsetMultiplier, default: type.defaultOffsetMultiplier)

        if !isScrolling, !isDecelerating, autoscroll == 0 {
            if scrollToItemBoundary, currentItemIndex != -1 {
                scrollToItem(at: currentItemIndex, animated: true)
            } else {
                storedScrollOffset = clampedOffset(storedScrollOffset)
            }
        }

        didScroll()
    }

    func updateItemWidth() {
        let delegateWidth = delegate?.carouselItemWidth(self) ?? 0
        if delegateWidth > 0 {
            itemWidth = delegateWidth
        }

        if numberOfItems > 0 {
            if itemContainers.isEmpty {
                _ = loadView(at: 0)
            }
        } else if numberOfPlaceholders > 0 {
            if itemContainers.isEmpty {
                _ = loadView(at: -1)
            }
        }
    }

    var circularItemCount: Int {
        switch type {
        case .rotary, .invertedRotary, .cylinder, .invertedCylinder, .wheel, .invertedWheel:
            guard itemWidth > 0 else { return 0 }

            let spacing = optionValue(.spacing, default: 1)
            let width = isVertical ? bounds.height : bounds.width
            var count = min(CGFloat(Self.maxVisibleItems), max(12, ceil(width / (spacing * itemWidth)) * .pi))
            count = min(CGFloat(numberOfItems + numberOfPlaceholdersToShow), count)
            return max(0, Int(optionValue(.count, default: count)))
        case .coverFlow, .coverFlow2, .timeMachine, .invertedTimeMachine, .linear, .custom:
            return numberOfItems + numberOfPlaceholdersToShow
        }
    }

    func updateNumberOfVisibleItems() {
        guard itemWidth > 0 else {
            visibleItemCount = 0
            return
        }

        switch type {
        case .linear:
            let spacing = optionValue(.spacing, default: 1)
            let width = isVertical ? bounds.height : bounds.width
            visibleItemCount = Int(ceil(width / (itemWidth * spacing))) + 2

        case .coverFlow, .coverFlow2:
            let spacing = optionValue(.spacing, default: 0.25)
            let width = isVertical ? bounds.height : bounds.width
            visibleItemCount = Int(ceil(width / (itemWidth * spacing))) + 2

        case .rotary, .cylinder:
            visibleItemCount = circularItemCount

        case .invertedRotary, .invertedCylinder:
            visibleItemCount = Int(ceil(Double(circularItemCount) / 2))

        case .wheel, .invertedWheel:
            let count = CGFloat(circularItemCount)
            let spacing = optionValue(.spacing, default: 1)
            let arc = optionValue(.arc, default: .pi * 2)
            let radius = optionValue(.radius, default: itemWidth * spacing * count / max(arc, Self.floatMargin))

            if radius - itemWidth / 2 < min(bounds.width, bounds.height) / 2 {
                visibleItemCount = Int(count)
            } else {
                visibleItemCount = Int(ceil(count / 2)) + 1
            }

        case .timeMachine, .invertedTimeMachine, .custom:
            visibleItemCount = Self.maxVisibleItems
        }

        visibleItemCount = min(Self.maxVisibleItems, visibleItemCount)
        visibleItemCount = Int(optionValue(.visibleItems, default: CGFloat(visibleItemCount)))
        visibleItemCount = max(0, min(visibleItemCount, numberOfItems + numberOfPlaceholdersToShow))
    }

    // MARK: - Alpha and transforms

    func alphaForItem(withOffset offset: CGFloat) -> CGFloat {
        var fadeMin = -CGFloat.infinity
        var fadeMax = CGFloat.infinity
        var fadeRange: CGFloat = 1
        var fadeMinAlpha: CGFloat = 0

        switch type {
        case .timeMachine:
            fadeMax = 0
        case .invertedTimeMachine:
            fadeMin = 0
        default:
            break
        }

        fadeMin = optionValue(.fadeMin, default: fadeMin)
        fadeMax = optionValue(.fadeMax, default: fadeMax)
        fadeRange = optionValue(.fadeRange, default: fadeRange)
        fadeMinAlpha = optionValue(.fadeMinAlpha, default: fadeMinAlpha)

        var factor: CGFloat = 0
        if offset > fadeMax {
            factor = offset - fadeMax
        } else if offset < fadeMin {
            factor = fadeMin - offset
        }

        guard fadeRange > 0 else { return 1 - min(factor, 1) }
        return 1 - min(factor, fadeRange) / fadeRange * (1 - fadeMinAlpha)
    }

    func transformForItem(withOffset offset: CGFloat) -> CATransform3D {
        var transform = CATransform3DIdentity
        transform.m34 = perspective
        transform = CATransform3DTranslate(transform, -viewpointOffset.width, -viewpointOffset.height, 0)

        switch type {
        case .custom:
            return delegate?.carousel(self, itemTransformForOffset: offset, baseTransform: transform) ?? transform

        case .linear:
            let spacing = optionValue(.spacing, default: 1)
            if isVertical {
                return CATransform3DTranslate(transform, 0, offset * itemWidth * spacing, 0)
            }
            return CATransform3DTranslate(transform, offset * itemWidth * spacing, 0, 0)

        case .rotary, .invertedRotary:
            let count = CGFloat(circularItemCount)
            guard count > 0 else { return transform }

            let spacing = optionValue(.spacing, default: 1)
            let arc = optionValue(.arc, default: .pi * 2)
            var radius = optionValue(
                .radius,
                default: max(itemWidth * spacing / 2, itemWidth * spacing / 2 / tan(arc / 2 / count))
            )
            var angle = optionValue(.angle, default: offset / count * arc)

            if type == .invertedRotary {
                radius = -radius
                angle = -angle
            }

            if isVertical {
                return CATransform3DTranslate(transform, 0, radius * sin(angle), radius * cos(angle) - radius)
            }
            return CATransform3DTranslate(transform, radius * sin(angle), 0, radius * cos(angle) - radius)

        case .cylinder, .invertedCylinder:
            let count = CGFloat(circularItemCount)
            guard count > 0 else { return transform }

            let spacing = optionValue(.spacing, default: 1)
            let arc = optionValue(.arc, default: .pi * 2)
            var radius = optionValue(
                .radius,
                default: max(0.01, itemWidth * spacing / 2 / tan(arc / 2 / count))
            )
            var angle = optionValue(.angle, default: offset / count * arc)

            if type == .invertedCylinder {
                radius = -radius
                angle = -angle
            }

            if isVertical {
                transform = CATransform3DTranslate(transform, 0, 0, -radius)
                transform = CATransform3DRotate(transform, angle, -1, 0, 0)
                return CATransform3DTranslate(transform, 0, 0, radius + 0.01)
            }

            transform = CATransform3DTranslate(transform, 0, 0, -radius)
            transform = CATransform3DRotate(transform, angle, 0, 1, 0)
            return CATransform3DTranslate(transform, 0, 0, radius + 0.01)

        case .wheel, .invertedWheel:
            let count = CGFloat(circularItemCount)
            guard count > 0 else { return transform }

            let spacing = optionValue(.spacing, default: 1)
            let arc = optionValue(.arc, default: .pi * 2)
            var radius = optionValue(.radius, default: itemWidth * spacing * count / arc)
            var angle = optionValue(.angle, default: arc / count)

            if type == .invertedWheel {
                radius = -radius
                angle = -angle
            }

            if isVertical {
                transform = CATransform3DTranslate(transform, -radius, 0, 0)
                transform = CATransform3DRotate(transform, angle * offset, 0, 0, 1)
                return CATransform3DTranslate(transform, radius, 0, offset * 0.01)
            }

            transform = CATransform3DTranslate(transform, 0, radius, 0)
            transform = CATransform3DRotate(transform, angle * offset, 0, 0, 1)
            return CATransform3DTranslate(transform, 0, -radius, offset * 0.01)

        case .coverFlow, .coverFlow2:
            let tilt = optionValue(.tilt, default: 0.9)
            let spacing = optionValue(.spacing, default: 0.25)
            var clampedOffset = min(1, max(-1, offset))

            if type == .coverFlow2 {
                if toggle > 0 {
                    if offset <= -0.5 {
                        clampedOffset = -1
                    } else if offset <= 0.5 {
                        clampedOffset = -toggle
                    } else if offset <= 1.5 {
                        clampedOffset = 1 - toggle
                    }
                } else {
                    if offset > 0.5 {
                        clampedOffset = 1
                    } else if offset > -0.5 {
                        clampedOffset = -toggle
                    } else if offset > -1.5 {
                        clampedOffset = -1 - toggle
                    }
                }
            }

            let x = (clampedOffset * 0.5 * tilt + offset * spacing) * itemWidth
            let z = abs(clampedOffset) * -itemWidth * 0.5

            if isVertical {
                transform = CATransform3DTranslate(transform, 0, x, z)
                return CATransform3DRotate(transform, -clampedOffset * .pi / 2 * tilt, -1, 0, 0)
            }

            transform = CATransform3DTranslate(transform, x, 0, z)
            return CATransform3DRotate(transform, -clampedOffset * .pi / 2 * tilt, 0, 1, 0)

        case .timeMachine, .invertedTimeMachine:
            var tilt = optionValue(.tilt, default: 0.3)
            var invertedOffset = offset
            let spacing = optionValue(.spacing, default: 1)

            if type == .invertedTimeMachine {
                tilt = -tilt
                invertedOffset = -invertedOffset
            }

            if isVertical {
                return CATransform3DTranslate(
                    transform,
                    0,
                    invertedOffset * itemWidth * tilt,
                    invertedOffset * itemWidth * spacing
                )
            }

            return CATransform3DTranslate(
                transform,
                invertedOffset * itemWidth * tilt,
                0,
                invertedOffset * itemWidth * spacing
            )
        }
    }

    func transformItemView(_ container: ItemContainer, at index: Int) {
        let offset = offsetForItem(at: index)
        container.layer.opacity = Float(alphaForItem(withOffset: offset))

        container.center = CGPoint(
            x: bounds.midX + contentOffset.width,
            y: bounds.midY + contentOffset.height
        )
        container.isUserInteractionEnabled = !centerItemWhenSelected || index == currentItemIndex

        let scale = traitCollection.displayScale
        if scale > 0 {
            container.layer.rasterizationScale = scale
        }

        container.layoutIfNeeded()

        let clampedOffset = min(1, max(-1, offset))
        if isDecelerating
            || (isScrolling && !isDragging && !didDrag)
            || (autoscroll != 0 && !isDragging)
            || (!isWrapEnabled && (storedScrollOffset < 0 || storedScrollOffset >= CGFloat(numberOfItems - 1))) {
            if offset > 0 {
                toggle = offset <= 0.5 ? -clampedOffset : 1 - clampedOffset
            } else {
                toggle = offset > -0.5 ? -clampedOffset : -1 - clampedOffset
            }
        }

        let transform = transformForItem(withOffset: offset)
        container.layer.transform = transform

        var showBackfaces = container.itemView.layer.isDoubleSided
        if showBackfaces {
            showBackfaces = type != .invertedCylinder
        }
        showBackfaces = optionValue(.showBackfaces, default: showBackfaces ? 1 : 0) >= 0.5
        container.isHidden = showBackfaces ? false : !(transform.m33 > 0)
    }

    func transformItemViews() {
        for (index, container) in Array(itemContainers) {
            transformItemView(container, at: index)
        }
    }
}
