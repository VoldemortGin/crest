import SwiftUI

/// The master view displayed inside the notch panel.
/// Routes to the appropriate sub-view based on the current NotchState.
/// Uses NotchShape for physical-notch screens and PillShape for external displays.
struct ContentView: View {
    @State var viewModel: NotchViewModel
    var featureViewModels: FeatureViewModels

    private var isPill: Bool {
        !viewModel.geometryInfo.hasPhysicalNotch
    }

    var body: some View {
        ZStack {
            // Background shape: notch or pill
            if isPill {
                pillBackground
            } else {
                notchBackground
            }

            // Content based on state, clipped to the appropriate shape
            if isPill {
                contentForState
                    .clipShape(PillShape(cornerRadius: viewModel.pillCornerRadius))
            } else {
                contentForState
                    .clipShape(
                        NotchShape(
                            topCornerRadius: viewModel.topCornerRadius,
                            bottomCornerRadius: viewModel.bottomCornerRadius
                        )
                    )
            }
        }
        .frame(width: viewModel.notchSize.width, height: viewModel.notchSize.height)
        .shadow(color: isPill ? .black.opacity(0.35) : .clear, radius: isPill ? 12 : 0, y: isPill ? 4 : 0)
        .animation(AnimationConstants.openSpring, value: viewModel.state)
    }

    // MARK: - Backgrounds

    @ViewBuilder
    private var notchBackground: some View {
        NotchShape(
            topCornerRadius: viewModel.topCornerRadius,
            bottomCornerRadius: viewModel.bottomCornerRadius
        )
        .fill(Color.black)
    }

    @ViewBuilder
    private var pillBackground: some View {
        PillShape(cornerRadius: viewModel.pillCornerRadius)
            .fill(.ultraThinMaterial)
            .environment(\.colorScheme, .dark)
        PillShape(cornerRadius: viewModel.pillCornerRadius)
            .fill(Color.black.opacity(0.55))
    }

    // MARK: - Content

    @ViewBuilder
    private var contentForState: some View {
        switch viewModel.state {
        case .closed:
            ClosedStateView(viewModel: viewModel, featureViewModels: featureViewModels)
                .transition(AnimationConstants.contentAppearTransition)

        case .sneakPeek(let event):
            SneakPeekView(event: event)
                .transition(AnimationConstants.contentAppearTransition)

        case .open:
            OpenStateView(viewModel: viewModel, featureViewModels: featureViewModels)
                .transition(AnimationConstants.contentAppearTransition)

        case .expandedDetail:
            ExpandedDetailView(viewModel: viewModel, featureViewModels: featureViewModels)
                .transition(AnimationConstants.contentAppearTransition)
        }
    }
}
