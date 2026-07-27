import SwiftUI

/// Displays minimal indicators in the closed notch state.
/// On physical-notch screens: battery, music bars, next event (current behavior).
/// On non-notch (pill) screens: floating widget with status indicators.
struct ClosedStateView: View {
    let viewModel: NotchViewModel
    let featureViewModels: FeatureViewModels

    private var isPill: Bool {
        !viewModel.geometryInfo.hasPhysicalNotch
    }

    var body: some View {
        Group {
            if isPill {
                pillClosedContent
            } else {
                notchClosedContent
            }
        }
        .onAppear {
            featureViewModels.monitor.startMonitoring()
            featureViewModels.calendar.startObserving()
        }
        .onDisappear {
            featureViewModels.monitor.stopMonitoring()
            featureViewModels.calendar.stopObserving()
        }
    }

    // MARK: - Notch Closed Content (Physical Notch)

    @ViewBuilder
    private var notchClosedContent: some View {
        HStack(spacing: 0) {
            batteryIndicator
                .frame(maxWidth: .infinity, alignment: .leading)

            MusicIndicatorView(isPlaying: featureViewModels.media.isPlaying)

            NextEventIndicator(event: featureViewModels.calendar.nextEvent)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Pill Closed Content (External Display)

    @ViewBuilder
    private var pillClosedContent: some View {
        HStack(spacing: 8) {
            // Leading: music playing indicator
            if featureViewModels.media.isPlaying {
                MusicIndicatorView(isPlaying: true)
                    .frame(width: 16, height: 16)
            } else {
                // Subtle dot when nothing is playing
                Circle()
                    .fill(.white.opacity(0.3))
                    .frame(width: 6, height: 6)
            }

            Spacer(minLength: 4)

            // Center/trailing: next calendar event
            NextEventIndicator(event: featureViewModels.calendar.nextEvent)

            // Trailing: battery if available
            if featureViewModels.monitor.hasBattery, let battery = featureViewModels.monitor.batteryInfo {
                HStack(spacing: 3) {
                    Image(systemName: batteryIconName(level: battery.level, charging: battery.isCharging))
                        .font(.system(size: 10))
                        .foregroundStyle(featureViewModels.monitor.batteryColor)

                    Text("\(battery.level)%")
                        .font(.system(size: 10).monospacedDigit())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Shared Helpers

    @ViewBuilder
    private var batteryIndicator: some View {
        if featureViewModels.monitor.hasBattery, let battery = featureViewModels.monitor.batteryInfo {
            HStack(spacing: 3) {
                Image(systemName: batteryIconName(level: battery.level, charging: battery.isCharging))
                    .font(.system(size: 10))
                    .foregroundStyle(featureViewModels.monitor.batteryColor)

                Text("\(battery.level)%")
                    .font(.system(size: 9).monospacedDigit())
                    .foregroundStyle(.white.opacity(0.7))
            }
        } else {
            Color.clear.frame(width: 1)
        }
    }

    private func batteryIconName(level: Int, charging: Bool) -> String {
        if charging { return "battery.100percent.bolt" }
        switch level {
        case 0..<13: return "battery.0percent"
        case 13..<38: return "battery.25percent"
        case 38..<63: return "battery.50percent"
        case 63..<88: return "battery.75percent"
        default: return "battery.100percent"
        }
    }
}
