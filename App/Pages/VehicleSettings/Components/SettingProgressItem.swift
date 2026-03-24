import SwiftUI

struct SettingProgressItem: View {
  let item: TemplateItem
  let payload: ProgressPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var value: Double = 0
  @State private var isUpdating = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Title
      VStack(alignment: .leading, spacing: 6) {
        Text(item.item ?? "")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(Color(hex: "0x111111"))

        if let describe = item.describe, !describe.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
          Text(describe)
            .font(.system(size: 14))
            .foregroundColor(ThemeColor.gray500)
            .fixedSize(horizontal: false, vertical: true)
        }
      }

      // Progress Bar
      GeometryReader { _ in
        let minValue = Double(payload.min ?? 0)
        let maxValue = Double(payload.max ?? 100)

        VStack(spacing: 10) {
          Slider(value: $value, in: minValue ... maxValue, step: 1) { editing in
            if !editing {
              updateValue()
            }
          }
          .accentColor(Color(hex: "0x06BAFF"))
          .disabled(isUpdating)

          HStack {
            Text("\(Int(minValue))")
              .font(.system(size: 13))
              .foregroundColor(Color(hex: "0x999999"))

            if let minDesc = payload.minDesc, !minDesc.isEmpty {
              Text("(\(minDesc))")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "0x999999"))
            }

            Spacer()

            if let maxDesc = payload.maxDesc, !maxDesc.isEmpty {
              Text("(\(maxDesc))")
                .font(.system(size: 13))
                .foregroundColor(Color(hex: "0x999999"))
            }

            Text("\(Int(maxValue))")
              .font(.system(size: 13))
              .foregroundColor(Color(hex: "0x999999"))
          }
        }
      }
      .frame(height: 55)
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .vehicleSettingsUpdatingOverlay(isUpdating)
    .onAppear {
      if let c = item.c, let v = store.settings[c]?.v, let doubleVal = Double(v) {
        value = doubleVal
      } else {
        value = Double(payload.min ?? 0)
      }
    }
  }

  private func updateValue() {
    isUpdating = true
    Task {
      let success = await store.updateSetting(item: item, value: String(Int(value)))
      if !success {
        ToastCenter.shared.show("设置失败，请稍后再试")
      }
      isUpdating = false
    }
  }
}

private struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.closeSubpath()
    return path
  }
}
