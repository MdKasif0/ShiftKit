import SwiftUI

// MARK: - Radial Sector Shape
public struct RadialSectorShape: Shape {
    public var startAngle: Angle
    public var endAngle: Angle
    public var innerRadius: CGFloat
    public var outerRadius: CGFloat

    public var animatableData: AnimatablePair<Double, Double> {
        get { AnimatablePair(startAngle.radians, endAngle.radians) }
        set {
            startAngle = Angle(radians: newValue.first)
            endAngle = Angle(radians: newValue.second)
        }
    }

    public init(startAngle: Angle, endAngle: Angle, innerRadius: CGFloat, outerRadius: CGFloat) {
        self.startAngle = startAngle
        self.endAngle = endAngle
        self.innerRadius = innerRadius
        self.outerRadius = outerRadius
    }

    public func path(in rect: CGRect) -> Path {
        let center = CGPoint(x: rect.midX, y: rect.midY)
        var path = Path()

        // Outer arc
        path.addArc(
            center: center,
            radius: outerRadius,
            startAngle: startAngle,
            endAngle: endAngle,
            clockwise: false
        )

        // Line to inner arc
        let innerEnd = CGPoint(
            x: center.x + innerRadius * CGFloat(cos(endAngle.radians)),
            y: center.y + innerRadius * CGFloat(sin(endAngle.radians))
        )
        path.addLine(to: innerEnd)

        // Inner arc (reverse direction)
        path.addArc(
            center: center,
            radius: innerRadius,
            startAngle: endAngle,
            endAngle: startAngle,
            clockwise: true
        )

        path.closeSubpath()
        return path
    }
}
