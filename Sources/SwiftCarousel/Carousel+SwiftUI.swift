//
//  Carousel+SwiftUI.swift
//  SwiftCarousel
//
//  SwiftUI wrapper for CarouselView.
//

#if canImport(SwiftUI)
import SwiftUI
import UIKit

/// A SwiftUI wrapper around ``CarouselView``.
///
/// The wrapper drives the carousel from a plain array of items. Each item gets a
/// `UIHostingController`, so SwiftUI state updates are reflected in visible cards.
@available(iOS 16.0, *)
public struct Carousel<Item, Content: View>: UIViewRepresentable {
    public var items: [Item]
    @Binding public var currentIndex: Int
    public var type: CarouselType
    public var itemSize: CGSize
    public var options: [CarouselOption: CGFloat]
    public var isVertical: Bool
    public var isPagingEnabled: Bool
    public var autoscroll: CGFloat
    public var accessibilityIdentifier: String?
    public var customTransform: ((CGFloat, CATransform3D) -> CATransform3D)?

    private let content: (Item, Int) -> Content

    public init(
        items: [Item],
        currentIndex: Binding<Int>,
        type: CarouselType = .coverFlow2,
        itemSize: CGSize = CGSize(width: 240, height: 300),
        options: [CarouselOption: CGFloat] = [:],
        isVertical: Bool = false,
        isPagingEnabled: Bool = false,
        autoscroll: CGFloat = 0,
        accessibilityIdentifier: String? = "carouselView",
        customTransform: ((CGFloat, CATransform3D) -> CATransform3D)? = nil,
        @ViewBuilder content: @escaping (Item, Int) -> Content
    ) {
        self.items = items
        self._currentIndex = currentIndex
        self.type = type
        self.itemSize = itemSize
        self.options = options
        self.isVertical = isVertical
        self.isPagingEnabled = isPagingEnabled
        self.autoscroll = autoscroll
        self.accessibilityIdentifier = accessibilityIdentifier
        self.customTransform = customTransform
        self.content = content
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> CarouselView {
        let view = CarouselView()
        view.backgroundColor = .clear
        view.dataSource = context.coordinator
        view.delegate = context.coordinator
        context.coordinator.configure(self, view: view, reload: true)
        return view
    }

    public func updateUIView(_ view: CarouselView, context: Context) {
        context.coordinator.configure(self, view: view, reload: false)

        guard context.coordinator.itemCount > 0,
              !view.isDragging,
              !view.isDecelerating,
              !view.isScrolling else {
            return
        }

        let target = min(max(0, currentIndex), context.coordinator.itemCount - 1)
        if view.currentItemIndex != target {
            view.scrollToItem(at: target, animated: false)
        }
    }

    @MainActor
    public final class Coordinator: NSObject, CarouselDataSource, CarouselDelegate {
        var parent: Carousel
        private(set) var itemCount = 0

        private var hostingControllers: [Int: UIHostingController<Content>] = [:]

        init(_ parent: Carousel) {
            self.parent = parent
        }

        func configure(_ parent: Carousel, view: CarouselView, reload: Bool) {
            let countChanged = parent.items.count != itemCount
            self.parent = parent
            itemCount = parent.items.count

            view.type = parent.type
            view.isVertical = parent.isVertical
            view.isPagingEnabled = parent.isPagingEnabled
            view.autoscroll = parent.autoscroll
            view.accessibilityIdentifier = parent.accessibilityIdentifier

            if reload || countChanged {
                hostingControllers.removeAll()
                view.reloadData()

                if itemCount > 0 {
                    let target = min(max(0, parent.currentIndex), itemCount - 1)
                    view.scrollToItem(at: target, animated: false)
                }
            } else {
                for (index, controller) in hostingControllers where index < parent.items.count {
                    controller.rootView = parent.content(parent.items[index], index)
                }
            }
        }

        // MARK: CarouselDataSource

        public func numberOfItems(in carousel: CarouselView) -> Int {
            parent.items.count
        }

        public func carousel(_ carousel: CarouselView, viewForItemAt index: Int, reusing view: UIView?) -> UIView {
            let controller: UIHostingController<Content>
            if let cached = hostingControllers[index] {
                controller = cached
            } else {
                controller = UIHostingController(rootView: parent.content(parent.items[index], index))
                controller.view.backgroundColor = .clear
                hostingControllers[index] = controller
            }

            controller.rootView = parent.content(parent.items[index], index)
            controller.view.frame = CGRect(origin: .zero, size: parent.itemSize)
            return controller.view
        }

        // MARK: CarouselDelegate

        public func carousel(_ carousel: CarouselView, didSelectItemAt index: Int) {
            parent.currentIndex = index
        }

        public func carouselCurrentItemIndexDidChange(_ carousel: CarouselView) {
            let index = max(0, carousel.currentItemIndex)
            if parent.currentIndex != index {
                parent.currentIndex = index
            }
        }

        public func carousel(_ carousel: CarouselView, valueForOption option: CarouselOption, withDefault value: CGFloat) -> CGFloat {
            parent.options[option] ?? value
        }

        public func carousel(
            _ carousel: CarouselView,
            itemTransformForOffset offset: CGFloat,
            baseTransform transform: CATransform3D
        ) -> CATransform3D {
            parent.customTransform?(offset, transform) ?? transform
        }
    }
}
#endif
