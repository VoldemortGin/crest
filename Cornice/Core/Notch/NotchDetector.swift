import AppKit

// MARK: - ScreenProviding Protocol

/// Abstracts NSScreen for testability.
protocol ScreenProviding: AnyObject {
    var frame: NSRect { get }
    var visibleFrame: NSRect { get }
    var safeAreaTop: CGFloat { get }
    var screenAuxiliaryTopLeftArea: NSRect? { get }
    var screenAuxiliaryTopRightArea: NSRect? { get }
    var screenDisplayID: CGDirectDisplayID { get }
    var screenLocalizedName: String { get }
}

/// Make NSScreen conform to ScreenProviding.
extension NSScreen: ScreenProviding {
    var safeAreaTop: CGFloat {
        safeAreaInsets.top
    }

    var screenAuxiliaryTopLeftArea: NSRect? {
        auxiliaryTopLeftArea
    }

    var screenAuxiliaryTopRightArea: NSRect? {
        auxiliaryTopRightArea
    }

    var screenDisplayID: CGDirectDisplayID {
        guard let screenNumber = deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
            return 0
        }
        return CGDirectDisplayID(screenNumber.uint32Value)
    }

    var screenLocalizedName: String {
        localizedName
    }
}

// MARK: - NotchDetector

/// Detects whether screens have a physical notch and computes notch geometry.
final class NotchDetector {

    /// Horizontal padding added to each side of the calculated notch width.
    /// This ensures the overlay slightly exceeds the physical notch boundary.
    static let horizontalPadding: CGFloat = 4.0

    /// Returns true if the given screen has a camera housing (notch).
    static func hasNotch(screen: ScreenProviding) -> Bool {
        return screen.safeAreaTop > 0
    }

    /// Calculates the notch width for a screen with a physical notch.
    /// Uses auxiliary top areas to determine the gap.
    static func notchWidth(for screen: ScreenProviding) -> CGFloat {
        guard hasNotch(screen: screen) else {
            return AnimationConstants.PillSizes.closedWidth
        }

        let screenWidth = screen.frame.width
        let leftWidth = screen.screenAuxiliaryTopLeftArea?.width ?? 0
        let rightWidth = screen.screenAuxiliaryTopRightArea?.width ?? 0

        let rawNotchWidth = screenWidth - leftWidth - rightWidth
        return rawNotchWidth + (2 * horizontalPadding)
    }

    /// Calculates the notch height based on the height mode.
    static func notchHeight(for screen: ScreenProviding, mode: NotchHeightMode) -> CGFloat {
        if hasNotch(screen: screen) {
            let descriptor = screenDescriptor(from: screen)
            return mode.height(for: descriptor)
        }
        // Non-notch screens use pill closed height.
        return AnimationConstants.PillSizes.closedHeight
    }

    /// Computes full geometry info for a given screen.
    static func geometryInfo(
        for screen: ScreenProviding,
        heightMode: NotchHeightMode = .matchNotch
    ) -> NotchGeometryInfo {
        let hasPhysical = hasNotch(screen: screen)

        let width: CGFloat
        let height: CGFloat
        let topOffset: CGFloat

        if hasPhysical {
            // Physical notch: use real notch dimensions, flush with top.
            width = notchWidth(for: screen)
            height = notchHeight(for: screen, mode: heightMode)
            topOffset = 0
        } else {
            // External / non-notch display: use pill dimensions, float below top.
            width = AnimationConstants.PillSizes.closedWidth
            height = AnimationConstants.PillSizes.closedHeight
            topOffset = AnimationConstants.PillSizes.topOffset
        }

        let notchRect = NSRect(
            x: screen.frame.midX - width / 2,
            y: screen.frame.maxY - height - topOffset,
            width: width,
            height: height
        )

        let closedSize = CGSize(width: width, height: height)

        let sneakPeekWidth: CGFloat
        let sneakPeekHeight: CGFloat
        if hasPhysical {
            sneakPeekWidth = min(AnimationConstants.Sizes.sneakPeekWidth, screen.frame.width * 0.4)
            sneakPeekHeight = AnimationConstants.Sizes.sneakPeekHeight
        } else {
            sneakPeekWidth = min(AnimationConstants.PillSizes.sneakPeekWidth, screen.frame.width * 0.4)
            sneakPeekHeight = AnimationConstants.PillSizes.sneakPeekHeight
        }
        let sneakPeekSize = CGSize(width: sneakPeekWidth, height: sneakPeekHeight)

        let openWidth = min(AnimationConstants.Sizes.openWidth, screen.frame.width * 0.6)
        let openHeight = AnimationConstants.Sizes.openHeight
        let openSize = CGSize(width: openWidth, height: openHeight)

        let expandedWidth = min(AnimationConstants.Sizes.expandedDetailWidth, screen.frame.width * 0.6)
        let expandedHeight = min(AnimationConstants.Sizes.expandedDetailHeight, screen.frame.height * 0.5)
        let expandedDetailSize = CGSize(width: expandedWidth, height: expandedHeight)

        return NotchGeometryInfo(
            hasPhysicalNotch: hasPhysical,
            notchRect: notchRect,
            closedSize: closedSize,
            openSize: openSize,
            sneakPeekSize: sneakPeekSize,
            expandedDetailSize: expandedDetailSize,
            screenFrame: screen.frame,
            topOffset: topOffset
        )
    }

    /// Creates a ScreenDescriptor from a ScreenProviding instance.
    static func screenDescriptor(from screen: ScreenProviding) -> ScreenDescriptor {
        ScreenDescriptor(
            frame: screen.frame,
            safeAreaTop: screen.safeAreaTop,
            auxiliaryTopLeftArea: screen.screenAuxiliaryTopLeftArea,
            auxiliaryTopRightArea: screen.screenAuxiliaryTopRightArea,
            displayID: screen.screenDisplayID,
            localizedName: screen.screenLocalizedName
        )
    }

    /// Returns all connected screens that have a physical notch.
    static func screensWithNotch() -> [NSScreen] {
        NSScreen.screens.filter { hasNotch(screen: $0) }
    }

    /// Returns the display UUID string for a given display ID.
    static func displayUUID(for displayID: CGDirectDisplayID) -> String {
        guard let uuid = CGDisplayCreateUUIDFromDisplayID(displayID) else {
            return "\(displayID)"
        }
        let cfUUID = uuid.takeRetainedValue()
        return CFUUIDCreateString(nil, cfUUID) as String
    }
}
