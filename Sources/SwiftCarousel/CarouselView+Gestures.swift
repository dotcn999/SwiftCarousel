//
//  CarouselView+Gestures.swift
//  SwiftCarousel
//
//  Ported from iCarousel 1.8.3 by Nick Lockwood.
//  https://github.com/nicklockwood/iCarousel — zlib license.
//

import UIKit

extension CarouselView {

    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if isScrollEnabled {
            isDragging = false
            isScrolling = false
            isDecelerating = false
        }

        if gestureRecognizer is UITapGestureRecognizer {
            if ancestor(of: touch.view, ofType: UIControl.self) != nil {
                return false
            }
            return true
        }

        if gestureRecognizer is UIPanGestureRecognizer {
            guard isScrollEnabled else { return false }

            if let scrollView = ancestor(of: touch.view, ofType: UIScrollView.self), scrollView.isScrollEnabled {
                let scrollsAlongAxis = isVertical
                    ? scrollView.contentSize.height > scrollView.bounds.height
                    : scrollView.contentSize.width > scrollView.bounds.width
                if scrollsAlongAxis {
                    return false
                }
            }
            return true
        }

        return true
    }

    public override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let pan = gestureRecognizer as? UIPanGestureRecognizer, ignorePerpendicularSwipes else {
            return true
        }

        let translation = pan.translation(in: self)
        if isVertical {
            return abs(translation.x) <= abs(translation.y)
        }
        return abs(translation.x) >= abs(translation.y)
    }

    @objc func handleTap(_ tap: UITapGestureRecognizer) {
        let point = tap.location(in: contentView)
        let tappedItemView = itemView(at: point)
        let tappedIndex = tappedItemView.flatMap { index(of: $0) }

        guard let index = tappedIndex else {
            scrollToItem(at: currentItemIndex, animated: true)
            return
        }

        if delegate?.carousel(self, shouldSelectItemAt: index) ?? true {
            if (index != currentItemIndex && centerItemWhenSelected)
                || (index == currentItemIndex && scrollToItemBoundary) {
                scrollToItem(at: index, animated: true)
            }
            delegate?.carousel(self, didSelectItemAt: index)
        } else if isScrollEnabled, scrollToItemBoundary, autoscroll != 0 {
            scrollToItem(at: currentItemIndex, animated: true)
        }
    }

    @objc func handlePan(_ pan: UIPanGestureRecognizer) {
        guard isScrollEnabled, numberOfItems > 0 else { return }

        let translation = isVertical ? pan.translation(in: self).y : pan.translation(in: self).x
        let velocity = isVertical ? pan.velocity(in: self).y : pan.velocity(in: self).x

        switch pan.state {
        case .began:
            isDragging = true
            isScrolling = false
            isDecelerating = false
            previousTranslation = translation
            delegate?.carouselWillBeginDragging(self)

        case .ended, .cancelled, .failed:
            isDragging = false
            didDrag = true

            if shouldDecelerate {
                didDrag = false
                startDecelerating()
            }

            delegate?.carousel(self, didEndDragging: isDecelerating)

            if !isDecelerating {
                let needsAlignment = scrollToItemBoundary
                    || abs(storedScrollOffset - clampedOffset(storedScrollOffset)) > Self.floatMargin

                if needsAlignment, autoscroll == 0 {
                    if abs(storedScrollOffset - CGFloat(currentItemIndex)) < Self.floatMargin {
                        // Trigger events for parity with the original implementation.
                        scrollToItem(at: currentItemIndex, duration: 0.01)
                    } else if shouldScroll {
                        let direction = startVelocity >= 0 ? 1 : -1
                        scrollToItem(at: currentItemIndex + direction, animated: true)
                    } else {
                        scrollToItem(at: currentItemIndex, animated: true)
                    }
                } else {
                    depthSort()
                }
            } else {
                delegate?.carouselWillBeginDecelerating(self)
            }

        case .changed:
            var factor: CGFloat = 1
            if !isWrapEnabled, bounces {
                let overshoot = abs(storedScrollOffset - clampedOffset(storedScrollOffset))
                factor = 1 - min(overshoot, bounceDistance) / max(bounceDistance, Self.floatMargin)
            }

            let width = max(itemWidth, Self.floatMargin)
            startVelocity = -velocity * factor * scrollSpeed / width
            storedScrollOffset -= (translation - previousTranslation) * factor * offsetMultiplier / width
            previousTranslation = translation
            didScroll()

        case .possible:
            break

        @unknown default:
            break
        }
    }

    func itemIndexOrSuperviewIndex(for view: UIView?) -> Int? {
        var current = view
        while let candidate = current, candidate !== contentView {
            if let index = index(of: candidate) {
                return index
            }
            current = candidate.superview
        }
        return nil
    }

    func ancestor<T: UIView>(of view: UIView?, ofType type: T.Type) -> T? {
        var current = view
        while let candidate = current, candidate !== contentView {
            if let match = candidate as? T {
                return match
            }
            current = candidate.superview
        }
        return nil
    }
}
