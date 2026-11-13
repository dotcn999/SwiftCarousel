import SwiftCarousel
import SwiftUI

struct DemoContentView: View {
    @State private var selection: Int
    @State private var type: CarouselType
    @State private var wrap: Bool
    @State private var vertical: Bool
    @State private var autoScroll: Bool

    private let items = Array(0..<20)

    init() {
        let defaults = UserDefaults.standard

        let typeValue = defaults.object(forKey: "demoType") == nil ? nil : defaults.integer(forKey: "demoType")
        _type = State(initialValue: typeValue.flatMap(CarouselType.init(rawValue:)) ?? .coverFlow2)
        _selection = State(initialValue: defaults.object(forKey: "demoIndex") == nil ? 0 : defaults.integer(forKey: "demoIndex"))
        _wrap = State(initialValue: defaults.bool(forKey: "demoWrap"))
        _vertical = State(initialValue: defaults.bool(forKey: "demoVertical"))
        _autoScroll = State(initialValue: defaults.bool(forKey: "demoAutoscroll"))
    }

    private var carouselOptions: [CarouselOption: CGFloat] {
        [.wrap: wrap ? 1 : 0]
    }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.05, green: 0.06, blue: 0.12), Color(red: 0.12, green: 0.05, blue: 0.18)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 10) {
                header

                Carousel(
                    items: items,
                    currentIndex: $selection,
                    type: type,
                    itemSize: CGSize(width: 230, height: 300),
                    options: carouselOptions,
                    isVertical: vertical,
                    autoscroll: autoScroll ? 0.5 : 0,
                    accessibilityIdentifier: "carouselView"
                ) { item, _ in
                    DemoCard(index: item)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                controls
            }
            .padding(.top, 8)
            .padding(.bottom, 18)
        }
        .preferredColorScheme(.dark)
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("SwiftCarousel")
                .font(.caption.weight(.semibold))
                .tracking(3)
                .foregroundStyle(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline) {
                Text(type.displayName)
                    .font(.title2.bold())
                    .foregroundStyle(.white)

                Spacer()

                Text("Item")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.5))

                Text("\(selection)")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .monospacedDigit()
                    .foregroundStyle(.white)
                    .accessibilityIdentifier("currentIndexLabel")
            }
        }
        .padding(.horizontal, 24)
    }

    private var controls: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                Menu {
                    ForEach(CarouselType.allCases.filter { $0 != .custom }, id: \.rawValue) { option in
                        Button {
                            type = option
                        } label: {
                            if option == type {
                                Label(option.displayName, systemImage: "checkmark")
                            } else {
                                Text(option.displayName)
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "square.grid.2x2.fill")
                        Text(type.displayName)
                    }
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Capsule().fill(Color.white.opacity(0.16)))
                    .foregroundStyle(.white)
                }

                Spacer(minLength: 4)

                ToggleChip(title: "Wrap", isOn: $wrap)
                ToggleChip(title: "Vertical", isOn: $vertical)
                ToggleChip(title: "Auto", isOn: $autoScroll)
            }
            .padding(.horizontal, 20)

            HStack(spacing: 28) {
                stepButton(systemImage: "chevron.left", offset: -1)
                Text("Drag the carousel")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.4))
                stepButton(systemImage: "chevron.right", offset: 1)
            }
        }
    }

    private func stepButton(systemImage: String, offset: Int) -> some View {
        Button {
            selection = min(max(0, selection + offset), items.count - 1)
        } label: {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .bold))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.white.opacity(0.14)))
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
    }
}

private struct ToggleChip: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        Button {
            isOn.toggle()
        } label: {
            Text(title)
                .font(.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Capsule().fill(isOn ? Color.white.opacity(0.92) : Color.white.opacity(0.12)))
                .foregroundStyle(isOn ? Color.black : Color.white)
        }
        .buttonStyle(.plain)
    }
}

private struct DemoCard: View {
    let index: Int

    private var hue: Double {
        Double(index % 12) / 12
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            Color(hue: hue, saturation: 0.55, brightness: 0.95),
                            Color(hue: hue, saturation: 0.8, brightness: 0.45)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            RoundedRectangle(cornerRadius: 30, style: .continuous)
                .stroke(Color.white.opacity(0.24), lineWidth: 1)

            VStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 26, weight: .medium))
                    .foregroundStyle(.white.opacity(0.8))

                Text("\(index)")
                    .font(.system(size: 76, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)

                Text("SWIFT CAROUSEL")
                    .font(.caption2.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.white.opacity(0.65))
            }
        }
        .padding(10)
        .shadow(color: .black.opacity(0.35), radius: 18, y: 12)
    }
}
