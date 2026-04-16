import SwiftUI

struct LoginLogoView: View {
  var body: some View {
    VStack(spacing: 22) {
      mascot
      Text("你好，我是 Aura")
        .font(.system(size: 56 / 2, weight: .semibold))
        .foregroundColor(Color(hex: "1B1F2A"))
    }
    .padding(.bottom, 6)
  }

  private var mascot: some View {
    ZStack {
      Ellipse()
        .fill(Color.black.opacity(0.07))
        .frame(width: 150 / 2, height: 24 / 2)
        .offset(y: 190 / 2)

      RoundedRectangle(cornerRadius: 70 / 2, style: .continuous)
        .fill(Color.white)
        .frame(width: 240 / 2, height: 190 / 2)
        .shadow(color: Color.black.opacity(0.06), radius: 12, x: 0, y: 8)
        .offset(y: 35 / 2)

      Path { path in
        path.move(to: CGPoint(x: 80, y: 30))
        path.addLine(to: CGPoint(x: 80, y: 10))
      }
      .stroke(Color(hex: "DFE4EA"), style: StrokeStyle(lineWidth: 4, lineCap: .round))

      Circle()
        .fill(Color(hex: "F6C726"))
        .frame(width: 24 / 2, height: 24 / 2)
        .offset(y: -10 / 2)

      Circle()
        .fill(Color(hex: "2F3740"))
        .frame(width: 30 / 2, height: 30 / 2)
        .offset(x: -38 / 2, y: 95 / 2)
      Circle()
        .fill(Color.white)
        .frame(width: 10 / 2, height: 10 / 2)
        .offset(x: -33 / 2, y: 90 / 2)

      Circle()
        .fill(Color(hex: "2F3740"))
        .frame(width: 30 / 2, height: 30 / 2)
        .offset(x: 38 / 2, y: 95 / 2)
      Circle()
        .fill(Color.white)
        .frame(width: 10 / 2, height: 10 / 2)
        .offset(x: 43 / 2, y: 90 / 2)

      Circle()
        .fill(Color(hex: "F4CFD6").opacity(0.45))
        .frame(width: 32 / 2, height: 32 / 2)
        .offset(x: -58 / 2, y: 122 / 2)
      Circle()
        .fill(Color(hex: "F4CFD6").opacity(0.45))
        .frame(width: 32 / 2, height: 32 / 2)
        .offset(x: 58 / 2, y: 122 / 2)

      Path { path in
        path.move(to: CGPoint(x: 72, y: 130))
        path.addQuadCurve(to: CGPoint(x: 88, y: 130), control: CGPoint(x: 80, y: 140))
      }
      .stroke(Color(hex: "2F3740"), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
    }
    .frame(width: 240 / 2, height: 220 / 2)
  }
}
