import SwiftUI

/// A pill/capsule shape for external (non-notch) displays, mimicking iPhone's Dynamic Island.
/// In closed state, uses full capsule rounding (cornerRadius = height/2).
/// Transitions smoothly to a rounded rectangle when expanded.
struct PillShape: Shape {
    var cornerRadius: CGFloat

    var animatableData: CGFloat {
        get { cornerRadius }
        set { cornerRadius = newValue }
    }

    func path(in rect: CGRect) -> Path {
        let r = min(cornerRadius, min(rect.width / 2, rect.height / 2))
        return Path(roundedRect: rect, cornerRadius: r)
    }
}

// MARK: - Factory Methods

extension PillShape {
    /// Closed pill: fully rounded capsule (cornerRadius = height / 2).
    static func closed() -> PillShape {
        PillShape(cornerRadius: AnimationConstants.PillSizes.closedHeight / 2)
    }

    /// Sneak peek: slightly less rounded than closed.
    static func sneakPeek() -> PillShape {
        PillShape(cornerRadius: AnimationConstants.PillSizes.sneakPeekHeight / 2)
    }

    /// Open: rounded rectangle with a fixed radius.
    static func open() -> PillShape {
        PillShape(cornerRadius: AnimationConstants.PillCornerRadii.open)
    }

    /// Expanded detail: larger rounded rectangle.
    static func expandedDetail() -> PillShape {
        PillShape(cornerRadius: AnimationConstants.PillCornerRadii.expandedDetail)
    }

    /// Returns the appropriate PillShape for a given state.
    static func shape(for state: NotchState) -> PillShape {
        switch state {
        case .closed:
            return .closed()
        case .sneakPeek:
            return .sneakPeek()
        case .open:
            return .open()
        case .expandedDetail:
            return .expandedDetail()
        }
    }
}
