import SwiftUI

struct QRCodeBindingScanFrameView: View {
  let scanLineOffset: CGFloat

  var body: some View {
    ZStack {
      RoundedRectangle(cornerRadius: 24)
        .fill(Color.white.opacity(0.001))
        .frame(width: 256, height: 256)

      CornerFrame()
        .stroke(Color.white, lineWidth: 4)
        .frame(width: 256, height: 256)

      LinearGradient(
        gradient: Gradient(colors: [Color.clear, Color(hex: "0x06BAFF"), Color.clear]),
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(height: 2)
      .offset(y: scanLineOffset - 128)
      .shadow(color: Color(hex: "0x06BAFF").opacity(0.9), radius: 6, x: 0, y: 0)
      .frame(width: 256 - 32)
      .allowsHitTesting(false)
      .clipped()
    }
    .frame(width: 256, height: 256)
  }
}

struct CornerFrame: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    let cornerLength: CGFloat = 40
    let radius: CGFloat = 24

    let tl = CGPoint(x: rect.minX, y: rect.minY)
    let tr = CGPoint(x: rect.maxX, y: rect.minY)
    let bl = CGPoint(x: rect.minX, y: rect.maxY)
    let br = CGPoint(x: rect.maxX, y: rect.maxY)

    path.addRoundedCorner(at: tl, radius: radius, length: cornerLength, edges: [.top, .leading])
    path.addRoundedCorner(at: tr, radius: radius, length: cornerLength, edges: [.top, .trailing])
    path.addRoundedCorner(at: bl, radius: radius, length: cornerLength, edges: [.bottom, .leading])
    path.addRoundedCorner(at: br, radius: radius, length: cornerLength, edges: [.bottom, .trailing])

    return path
  }
}

extension Path {
  mutating func addRoundedCorner(at point: CGPoint, radius: CGFloat, length: CGFloat, edges: [Edge]) {
    let isTop = edges.contains(.top)
    let isBottom = edges.contains(.bottom)
    let isLeading = edges.contains(.leading)
    let isTrailing = edges.contains(.trailing)

    if isTop, isLeading {
      move(to: CGPoint(x: point.x, y: point.y + length))
      addLine(to: CGPoint(x: point.x, y: point.y + radius))
      addQuadCurve(to: CGPoint(x: point.x + radius, y: point.y), control: point)
      addLine(to: CGPoint(x: point.x + length, y: point.y))
      return
    }
    if isTop, isTrailing {
      move(to: CGPoint(x: point.x - length, y: point.y))
      addLine(to: CGPoint(x: point.x - radius, y: point.y))
      addQuadCurve(to: CGPoint(x: point.x, y: point.y + radius), control: point)
      addLine(to: CGPoint(x: point.x, y: point.y + length))
      return
    }
    if isBottom, isLeading {
      move(to: CGPoint(x: point.x, y: point.y - length))
      addLine(to: CGPoint(x: point.x, y: point.y - radius))
      addQuadCurve(to: CGPoint(x: point.x + radius, y: point.y), control: point)
      addLine(to: CGPoint(x: point.x + length, y: point.y))
      return
    }
    if isBottom, isTrailing {
      move(to: CGPoint(x: point.x - length, y: point.y))
      addLine(to: CGPoint(x: point.x - radius, y: point.y))
      addQuadCurve(to: CGPoint(x: point.x, y: point.y - radius), control: point)
      addLine(to: CGPoint(x: point.x, y: point.y - length))
      return
    }
  }
}
