//
//  CarouselView.swift
//  SwiftCarousel
//
//  A Swift 6 / UIKit port of iCarousel 1.8.3 by Nick Lockwood.
//  Original: https://github.com/nicklockwood/iCarousel — zlib license.
//

import QuartzCore
import UIKit

/// A carousel that displays an arbitrary sequence of views using one of
/// several 3D layouts, with drag physics, paging, wrapping and view recycling.
@MainActor
public final class CarouselView: UIView, UIGestureRecognizerDelegate {

    // MARK: - Data

    public weak var dataSource: CarouselDataSource? {
        didSet {
            guard dataSource !== oldValue else { return }
            if dataSource != nil {
                reloadData()
            } else {
                removeAllViews()
                numberOfItems = 0
                numberOfPlaceholders = 0
                visibleItemCount = 0
            }
        }
    }

    public weak var delegate: CarouselDelegate? {
        didSet {
            guard delegate !== oldValue else { return }
            if delegate != nil, dataSource != nil {
                setNeedsLayout()
            }
        }
    }

    // MARK: - Appearance and behaviour

    public var type: CarouselType = .linear {
        didSet {
            if type != oldValue {
                layoutItemViews()
            }
        }
    }

    public var perspective: CGFloat = -1.0 / 500.0 {
        didSet { transformItemViews() }
    }

    public var decelerationRate: CGFloat = 0.95
    public var scrollSpeed: CGFloat = 1
    public var bounceDistance: CGFloat = 1

    public var isScrollEnabled = true
    public var isPagingEnabled = false

    public var isVertical = false {
        didSet {
            if isVertical != oldValue {
                layoutItemViews()
            }
        }
    }

    public internal(set) var isWrapEnabled = false
    public var bounces = true

    public var scrollOffset: CGFloat {
        get { storedScrollOffset }
        set {
            isScrolling = false
            isDecelerating = false
            startOffset = newValue
            endOffset = newValue
            if abs(storedScrollOffset - newValue) > 0 {
                storedScrollOffset = newValue
                depthSort()
                didScroll()
            }
        }
    }

    public internal(set) var offsetMultiplier: CGFloat = 1

    public var contentOffset: CGSize = .zero {
        didSet {
            if contentOffset != oldValue {
                layoutItemViews()
            }
        }
    }

    public var viewpointOffset: CGSize = .zero {
        didSet {
            if viewpointOffset != oldValue {
                transformItemViews()
            }
        }
    }

    public internal(set) var numberOfItems = 0
    public internal(set) var numberOfPlaceholders = 0

    public var currentItemIndex: Int {
        get { clampedIndex(Int(storedScrollOffset.rounded())) }
        set { scrollOffset = CGFloat(newValue) }
    }

    public var currentItemView: UIView? {
        guard currentItemIndex >= 0 else { return nil }
        return itemContainers[currentItemIndex]?.itemView
    }

    public var indexesForVisibleItems: [Int] {
        itemContainers.keys.sorted()
    }

    public var numberOfVisibleItems: Int {
        visibleItemCount
    }

    public var visibleItemViews: [UIView] {
        indexesForVisibleItems.compactMap { itemContainers[$0]?.itemView }
    }

    public internal(set) var itemWidth: CGFloat = 0

    /// The view that hosts item containers. Exposed for parity with the original API.
    public let contentView = UIView()

    public internal(set) var toggle: CGFloat = 0

    /// Items per second. Positive values scroll backwards, matching the original library.
    public var autoscroll: CGFloat = 0 {
        didSet {
            if autoscroll != 0 {
                startAnimation()
            }
        }
    }

    public var stopAtItemBoundary = true
    public var scrollToItemBoundary = true
    public var ignorePerpendicularSwipes = true
    public var centerItemWhenSelected = true

    public internal(set) var isDragging = false
    public internal(set) var isDecelerating = false
    public internal(set) var isScrolling = false

    // MARK: - Internal state

    static let minToggleDuration: TimeInterval = 0.2
    static let maxToggleDuration: TimeInterval = 0.4
    static let scrollAnimationDuration: TimeInterval = 0.4
    static let insertAnimationDuration: TimeInterval = 0.4
    static let decelerateThreshold: CGFloat = 0.1
    static let scrollSpeedThreshold: CGFloat = 2
    static let scrollDistanceThreshold: CGFloat = 0.1
    static let decelerationMultiplier: CGFloat = 30
    static let floatMargin: CGFloat = 0.000001
    static let maxVisibleItems = 30

    var storedScrollOffset: CGFloat = 0
    var itemContainers: [Int: ItemContainer] = [:]
    var itemViewPool: Set<UIView> = []
    var placeholderViewPool: Set<UIView> = []
    var previousScrollOffset: CGFloat = 0
    var previousItemIndex = 0
    var numberOfPlaceholdersToShow = 0
    var visibleItemCount = 0
    var startOffset: CGFloat = 0
    var endOffset: CGFloat = 0
    var scrollDuration: TimeInterval = 0
    var startTime: CFTimeInterval = 0
    var lastTime: CFTimeInterval = 0
    var startVelocity: CGFloat = 0
    var previousTranslation: CGFloat = 0
    var didDrag = false
    var toggleTime: CFTimeInterval = 0

    private var displayLink: CADisplayLink?
    private var displayLinkProxy: DisplayLinkProxy?

    // MARK: - Lifecycle

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setUp()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        setUp()
    }

    private func setUp() {
        contentView.frame = bounds
        contentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        addSubview(contentView)

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        pan.delegate = self
        contentView.addGestureRecognizer(pan)

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.delegate = self
        contentView.addGestureRecognizer(tap)

        isAccessibilityElement = true
        accessibilityTraits = [.allowsDirectInteraction]
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = bounds
        layoutItemViews()
    }

    public override func didMoveToWindow() {
        super.didMoveToWindow()
        if window != nil {
            startAnimation()
        } else {
            stopAnimation()
        }
    }

    public override func accessibilityIncrement() {
        scrollToItem(at: currentItemIndex + 1, animated: true)
    }

    public override func accessibilityDecrement() {
        scrollToItem(at: currentItemIndex - 1, animated: true)
    }

    // MARK: - Public API

    public func reloadData() {
        removeAllViews()
        guard let dataSource else {
            numberOfItems = 0
            numberOfPlaceholders = 0
            visibleItemCount = 0
            setNeedsLayout()
            return
        }

        visibleItemCount = 0
        numberOfItems = dataSource.numberOfItems(in: self)
        numberOfPlaceholders = dataSource.numberOfPlaceholders(in: self)

        itemViewPool.removeAll()
        placeholderViewPool.removeAll()

        isScrolling = false
        isDecelerating = false
        isDragging = false
        didDrag = false
        toggle = 0

        setNeedsLayout()
        layoutIfNeeded()

        if numberOfItems > 0, storedScrollOffset < 0 {
            scrollToItem(at: 0, animated: numberOfPlaceholders > 0)
        }
    }

    public func itemView(at index: Int) -> UIView? {
        itemContainers[index]?.itemView
    }

    public func index(of view: UIView) -> Int? {
        for (index, container) in itemContainers where container.itemView === view {
            return index
        }
        return nil
    }

    public func indexOfItemViewOrSubview(_ view: UIView) -> Int? {
        if let index = index(of: view) {
            return index
        }
        guard let superview = view.superview, superview !== contentView else {
            return nil
        }
        return indexOfItemViewOrSubview(superview)
    }

    public func itemView(at point: CGPoint) -> UIView? {
        for container in depthSortedContainers().reversed() {
            if container.layer.hitTest(point) != nil {
                return container.itemView
            }
        }
        return nil
    }

    public func scrollToItem(at index: Int, animated: Bool) {
        scrollToItem(at: index, duration: animated ? Self.scrollAnimationDuration : 0)
    }

    public func scrollToItem(at index: Int, duration: TimeInterval) {
        scrollTo(offset: CGFloat(index), duration: duration)
    }

    public func scrollBy(offset: CGFloat, duration: TimeInterval) {
        if duration > 0 {
            isDecelerating = false
            isScrolling = true
            startTime = CACurrentMediaTime()
            startOffset = storedScrollOffset
            scrollDuration = duration
            endOffset = startOffset + offset
            if !isWrapEnabled {
                endOffset = clampedOffset(endOffset)
            }
            delegate?.carouselWillBeginScrollingAnimation(self)
            startAnimation()
        } else {
            scrollOffset += offset
        }
    }

    public func scrollTo(offset: CGFloat, duration: TimeInterval) {
        scrollBy(offset: minScrollDistance(fromOffset: storedScrollOffset, toOffset: offset), duration: duration)
    }

    public func scroll(byNumberOfItems count: Int, duration: TimeInterval) {
        if duration > 0 {
            let offset: CGFloat
            if count > 0 {
                offset = (floor(storedScrollOffset) + CGFloat(count)) - storedScrollOffset
            } else if count < 0 {
                offset = (ceil(storedScrollOffset) + CGFloat(count)) - storedScrollOffset
            } else {
                offset = storedScrollOffset.rounded() - storedScrollOffset
            }
            scrollBy(offset: offset, duration: duration)
        } else {
            scrollOffset = CGFloat(clampedIndex(previousItemIndex + count))
        }
    }

    public func removeItem(at index: Int, animated: Bool) {
        guard numberOfItems > 0 else { return }
        let index = clampedIndex(index)
        guard index >= 0 else { return }

        let container = itemContainers[index]

        if animated {
            if let container {
                UIView.animate(withDuration: 0.1, animations: {
                    container.layer.opacity = 0
                }, completion: { [weak self] _ in
                    guard let self else { return }
                    self.enqueue(container.itemView, placeholder: false)
                    container.removeFromSuperview()
                })
            }

            UIView.animate(withDuration: Self.insertAnimationDuration, delay: 0.1, animations: {
                self.removeMapping(at: index)
                self.numberOfItems -= 1
                self.isWrapEnabled = self.boolOption(.wrap, default: self.type.isCircular)
                self.updateNumberOfVisibleItems()
                self.storedScrollOffset = CGFloat(self.currentItemIndex)
                self.didScroll()
            }, completion: { _ in
                self.depthSort()
            })
        } else {
            if let container {
                enqueue(container.itemView, placeholder: false)
                container.removeFromSuperview()
            }
            removeMapping(at: index)
            numberOfItems -= 1
            isWrapEnabled = boolOption(.wrap, default: type.isCircular)
            updateNumberOfVisibleItems()
            storedScrollOffset = CGFloat(currentItemIndex)
            didScroll()
            depthSort()
        }
    }

    public func insertItem(at index: Int, animated: Bool) {
        numberOfItems += 1
        isWrapEnabled = boolOption(.wrap, default: type.isCircular)
        updateNumberOfVisibleItems()

        let index = clampedIndex(index)
        guard index >= 0 else { return }

        insertMapping(at: index)
        _ = loadView(at: index)

        if abs(itemWidth) < Self.floatMargin {
            updateItemWidth()
        }

        if animated {
            UIView.animate(withDuration: Self.insertAnimationDuration, animations: {
                self.transformItemViews()
            }, completion: { _ in
                self.didScroll()
            })
        } else {
            didScroll()
        }

        if storedScrollOffset < 0 {
            scrollToItem(at: 0, animated: animated && numberOfPlaceholders > 0)
        }
    }

    public func reloadItem(at index: Int, animated: Bool) {
        guard let container = itemContainers[index] else { return }

        if animated {
            let transition = CATransition()
            transition.duration = Self.insertAnimationDuration
            transition.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            transition.type = .fade
            container.layer.add(transition, forKey: nil)
        }

        _ = loadView(at: index, into: container)
    }

    // MARK: - View loading

    func removeAllViews() {
        for container in itemContainers.values {
            container.removeFromSuperview()
        }
        itemContainers.removeAll()
    }

    func makeContainer(for itemView: UIView) -> ItemContainer {
        if itemWidth == 0 {
            itemWidth = isVertical ? itemView.bounds.height : itemView.bounds.width
        }

        var frame = itemView.bounds
        if isVertical {
            frame.size.width = itemView.bounds.width
            frame.size.height = itemWidth
        } else {
            frame.size.width = itemWidth
            frame.size.height = itemView.bounds.height
        }

        let container = ItemContainer(frame: frame, itemView: itemView)
        container.layer.opacity = 0
        return container
    }

    @discardableResult
    func loadView(at index: Int, into existingContainer: ItemContainer? = nil) -> UIView {
        let itemView: UIView
        if index < 0 {
            let placeholderIndex = Int(ceil(Double(numberOfPlaceholdersToShow) / 2)) + index
            itemView = dataSource?.carousel(self, placeholderViewAt: placeholderIndex, reusing: dequeuePlaceholderView())
                ?? UIView()
        } else if index >= numberOfItems {
            let placeholderIndex = numberOfPlaceholdersToShow / 2 + index - numberOfItems
            itemView = dataSource?.carousel(self, placeholderViewAt: placeholderIndex, reusing: dequeuePlaceholderView())
                ?? UIView()
        } else {
            itemView = dataSource?.carousel(self, viewForItemAt: index, reusing: dequeueItemView())
                ?? UIView()
        }

        let container: ItemContainer
        if let existingContainer {
            enqueue(existingContainer.itemView, placeholder: index < 0 || index >= numberOfItems)
            existingContainer.itemView.removeFromSuperview()

            existingContainer.itemView = itemView
            var frame = existingContainer.bounds
            if isVertical {
                frame.size.width = itemView.frame.width
                frame.size.height = min(itemWidth, itemView.frame.height)
            } else {
                frame.size.width = min(itemWidth, itemView.frame.width)
                frame.size.height = itemView.frame.height
            }
            existingContainer.bounds = frame
            existingContainer.addSubview(itemView)
            container = existingContainer
            itemContainers[index] = container
        } else {
            container = makeContainer(for: itemView)
            itemContainers[index] = container
            contentView.addSubview(container)
        }

        center(itemView, in: container)
        container.layer.opacity = 0
        transformItemView(container, at: index)
        return itemView
    }

    func center(_ itemView: UIView, in container: ItemContainer) {
        var frame = itemView.frame
        frame.origin.x = (container.bounds.width - frame.width) / 2
        frame.origin.y = (container.bounds.height - frame.height) / 2
        itemView.frame = frame
    }

    func loadUnloadViews() {
        updateItemWidth()
        updateNumberOfVisibleItems()

        let total = numberOfItems + numberOfPlaceholdersToShow
        guard total > 0, visibleItemCount > 0 else {
            for (index, container) in Array(itemContainers) {
                enqueue(container.itemView, placeholder: index < 0 || index >= numberOfItems)
                container.removeFromSuperview()
                itemContainers[index] = nil
            }
            return
        }

        var visibleIndices = Set<Int>()
        let minIndex = -Int(ceil(Double(numberOfPlaceholdersToShow) / 2))
        let maxIndex = numberOfItems - 1 + numberOfPlaceholdersToShow / 2
        var offset = currentItemIndex - visibleItemCount / 2
        if !isWrapEnabled {
            offset = max(minIndex, min(maxIndex - visibleItemCount + 1, offset))
        }

        for i in 0..<visibleItemCount {
            var index = i + offset
            if isWrapEnabled {
                index = clampedIndex(index)
            }
            if alphaForItem(withOffset: offsetForItem(at: index)) != 0 {
                visibleIndices.insert(index)
            }
        }

        for (index, container) in Array(itemContainers) where !visibleIndices.contains(index) {
            enqueue(container.itemView, placeholder: index < 0 || index >= numberOfItems)
            container.removeFromSuperview()
            itemContainers[index] = nil
        }

        for index in visibleIndices where itemContainers[index] == nil {
            _ = loadView(at: index)
        }
    }

    func enqueue(_ view: UIView, placeholder: Bool) {
        if placeholder {
            placeholderViewPool.insert(view)
        } else {
            itemViewPool.insert(view)
        }
    }

    func dequeueItemView() -> UIView? {
        guard let view = itemViewPool.first else { return nil }
        itemViewPool.remove(view)
        return view
    }

    func dequeuePlaceholderView() -> UIView? {
        guard let view = placeholderViewPool.first else { return nil }
        placeholderViewPool.remove(view)
        return view
    }

    // MARK: - Mapping

    func removeMapping(at index: Int) {
        var newContainers: [Int: ItemContainer] = [:]
        for (i, container) in itemContainers {
            if i < index {
                newContainers[i] = container
            } else if i > index {
                newContainers[i - 1] = container
            }
        }
        itemContainers = newContainers
    }

    func insertMapping(at index: Int) {
        var newContainers: [Int: ItemContainer] = [:]
        for (i, container) in itemContainers {
            if i < index {
                newContainers[i] = container
            } else {
                newContainers[i + 1] = container
            }
        }
        itemContainers = newContainers
    }

    // MARK: - Scrolling state

    func didScroll() {
        if isWrapEnabled || !bounces {
            storedScrollOffset = clampedOffset(storedScrollOffset)
        } else {
            let minOffset = -bounceDistance
            let maxOffset = max(CGFloat(numberOfItems - 1), 0) + bounceDistance
            if storedScrollOffset < minOffset {
                storedScrollOffset = minOffset
                startVelocity = 0
            } else if storedScrollOffset > maxOffset {
                storedScrollOffset = maxOffset
                startVelocity = 0
            }
        }

        let difference = minScrollDistance(fromIndex: currentItemIndex, toIndex: previousItemIndex)
        if difference != 0 {
            toggleTime = CACurrentMediaTime()
            toggle = min(1, max(-1, CGFloat(difference)))
            startAnimation()
        }

        loadUnloadViews()
        transformItemViews()

        if abs(storedScrollOffset - previousScrollOffset) > Self.floatMargin {
            delegate?.carouselDidScroll(self)
        }

        if previousItemIndex != currentItemIndex {
            delegate?.carouselCurrentItemIndexDidChange(self)
        }

        previousScrollOffset = storedScrollOffset
        previousItemIndex = currentItemIndex
    }

    var decelerationDistance: CGFloat {
        let acceleration = -startVelocity * Self.decelerationMultiplier * (1 - decelerationRate)
        guard acceleration != 0 else { return 0 }
        return -pow(startVelocity, 2) / (2 * acceleration)
    }

    var shouldDecelerate: Bool {
        abs(startVelocity) > Self.scrollSpeedThreshold && abs(decelerationDistance) > Self.decelerateThreshold
    }

    var shouldScroll: Bool {
        abs(startVelocity) > Self.scrollSpeedThreshold
            && abs(storedScrollOffset - CGFloat(currentItemIndex)) > Self.scrollDistanceThreshold
    }

    func startDecelerating() {
        let distance = decelerationDistance
        startOffset = storedScrollOffset
        endOffset = startOffset + distance

        if isPagingEnabled {
            endOffset = distance > 0 ? ceil(startOffset) : floor(startOffset)
        } else if stopAtItemBoundary {
            endOffset = distance > 0 ? ceil(endOffset) : floor(endOffset)
        }

        if !isWrapEnabled {
            if bounces {
                endOffset = max(-bounceDistance, min(CGFloat(numberOfItems - 1) + bounceDistance, endOffset))
            } else {
                endOffset = clampedOffset(endOffset)
            }
        }

        let finalDistance = endOffset - startOffset
        startTime = CACurrentMediaTime()
        scrollDuration = abs(finalDistance) / max(abs(0.5 * startVelocity), Self.floatMargin)

        if finalDistance != 0 {
            isDecelerating = true
            startAnimation()
        }
    }

    func easeInOut(_ time: CGFloat) -> CGFloat {
        time < 0.5
            ? 0.5 * pow(time * 2, 3)
            : 0.5 * pow(time * 2 - 2, 3) + 1
    }

    // MARK: - Animation

    func startAnimation() {
        guard displayLink == nil else { return }
        let proxy = DisplayLinkProxy(carousel: self)
        let link = CADisplayLink(target: proxy, selector: #selector(DisplayLinkProxy.tick(_:)))
        link.add(to: .main, forMode: .common)
        displayLink = link
        displayLinkProxy = proxy
        lastTime = CACurrentMediaTime()
    }

    func stopAnimation() {
        displayLink?.invalidate()
        displayLink = nil
        displayLinkProxy = nil
    }

    func step() {
        let currentTime = CACurrentMediaTime()
        let delta = currentTime - lastTime
        lastTime = currentTime

        if isScrolling, !isDragging {
            let time = min(1, (currentTime - startTime) / max(scrollDuration, .leastNonzeroMagnitude))
            let eased = easeInOut(time)
            storedScrollOffset = startOffset + (endOffset - startOffset) * eased
            didScroll()

            if time >= 1 {
                isScrolling = false
                depthSort()
                delegate?.carouselDidEndScrollingAnimation(self)
            }
        } else if isDecelerating {
            let time = min(scrollDuration, currentTime - startTime)
            let acceleration = -startVelocity / max(scrollDuration, .leastNonzeroMagnitude)
            let distance = startVelocity * time + 0.5 * acceleration * time * time
            storedScrollOffset = startOffset + distance
            didScroll()

            if abs(time - scrollDuration) < Self.floatMargin {
                isDecelerating = false
                delegate?.carouselDidEndDecelerating(self)

                if (scrollToItemBoundary || abs(storedScrollOffset - clampedOffset(storedScrollOffset)) > Self.floatMargin),
                   autoscroll == 0 {
                    if abs(storedScrollOffset - CGFloat(currentItemIndex)) < Self.floatMargin {
                        // Trigger events for parity with the original implementation.
                        scrollToItem(at: currentItemIndex, duration: 0.01)
                    } else {
                        scrollToItem(at: currentItemIndex, animated: true)
                    }
                } else {
                    var difference = storedScrollOffset.rounded() - storedScrollOffset
                    if difference > 0.5 {
                        difference -= 1
                    } else if difference < -0.5 {
                        difference += 1
                    }
                    toggleTime = currentTime - Self.maxToggleDuration * abs(difference)
                    toggle = min(1, max(-1, -difference))
                }
            }
        } else if autoscroll != 0, !isDragging {
            scrollOffset = clampedOffset(storedScrollOffset - delta * autoscroll)
        } else if abs(toggle) > Self.floatMargin {
            let normalizedSpeed = startVelocity != 0 ? min(1, max(0, 1 / abs(startVelocity))) : 1
            let toggleDuration = Self.minToggleDuration
                + (Self.maxToggleDuration - Self.minToggleDuration) * normalizedSpeed
            let time = min(1, (currentTime - toggleTime) / toggleDuration)
            let eased = easeInOut(time)
            toggle = toggle < 0 ? eased - 1 : 1 - eased
            didScroll()
        } else if autoscroll == 0 {
            stopAnimation()
        }
    }

    // MARK: - Depth sorting

    func depthValue(_ transform: CATransform3D) -> CGFloat {
        transform.m13 + transform.m23 + transform.m33 + transform.m43
    }

    func depthSortedContainers() -> [ItemContainer] {
        let currentTransform = itemContainers[currentItemIndex]?.layer.transform

        return itemContainers.values.sorted { first, second in
            let firstTransform = first.layer.transform
            let secondTransform = second.layer.transform
            let firstDepth = depthValue(firstTransform)
            let secondDepth = depthValue(secondTransform)
            let difference = firstDepth - secondDepth

            if difference != 0 {
                return difference < 0
            }

            guard let currentTransform else { return false }

            if isVertical {
                let firstPosition = firstTransform.m12 + firstTransform.m22 + firstTransform.m32 + firstTransform.m42
                let secondPosition = secondTransform.m12 + secondTransform.m22 + secondTransform.m32 + secondTransform.m42
                let currentPosition = currentTransform.m12 + currentTransform.m22 + currentTransform.m32 + currentTransform.m42
                return abs(secondPosition - currentPosition) - abs(firstPosition - currentPosition) < 0
            } else {
                let firstPosition = firstTransform.m11 + firstTransform.m21 + firstTransform.m31 + firstTransform.m41
                let secondPosition = secondTransform.m11 + secondTransform.m21 + secondTransform.m31 + secondTransform.m41
                let currentPosition = currentTransform.m11 + currentTransform.m21 + currentTransform.m31 + currentTransform.m41
                return abs(secondPosition - currentPosition) - abs(firstPosition - currentPosition) < 0
            }
        }
    }

    func depthSort() {
        for container in depthSortedContainers() {
            contentView.bringSubviewToFront(container)
        }
    }
}

// MARK: - Supporting types

final class ItemContainer: UIView {
    var itemView: UIView

    init(frame: CGRect, itemView: UIView) {
        self.itemView = itemView
        super.init(frame: frame)
        addSubview(itemView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

@MainActor
private final class DisplayLinkProxy: NSObject {
    weak var carousel: CarouselView?

    init(carousel: CarouselView) {
        self.carousel = carousel
    }

    @objc func tick(_ link: CADisplayLink) {
        guard let carousel else {
            link.invalidate()
            return
        }
        carousel.step()
    }
}
