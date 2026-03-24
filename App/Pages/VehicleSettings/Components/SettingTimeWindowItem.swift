import SwiftUI

struct SettingTimeWindowItem: View {
  let item: TemplateItem
  let payload: TimeWindowPayload
  @ObservedObject private var store = TemplateStore.shared
  @State private var value: Double = 0
  @State private var isUpdating = false

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .firstTextBaseline, spacing: 0) {
        Text(item.item ?? "")
          .font(.system(size: 18, weight: .medium))
          .foregroundColor(ThemeColor.gray900)

        Text("（前\(frontSeconds)秒+后\(behindSeconds)秒）")
          .font(.system(size: 16, weight: .regular))
          .foregroundColor(ThemeColor.brand500)
      }

      barView

      // 写死的，目前协议不支持编译字符串
      Text("抓拍视频和\"时空流上传\"语音指令，触发的上传将包含触发时的前\(frontSeconds)秒和后\(behindSeconds)秒的视频")
        .font(.system(size: 14))
        .foregroundColor(Color(hex: "0x999999"))
        .fixedSize(horizontal: false, vertical: true)
    }
    .padding(.vertical, 12)
    .background(Color.white)
    .cornerRadius(8)
    .vehicleSettingsUpdatingOverlay(isUpdating)
    .onAppear {
      if let c = item.c, let v = store.settings[c]?.v, let doubleVal = Double(v) {
        value = doubleVal
      } else {
        value = Double(payload.min ?? 0)
      }
    }
  }

  private var minValue: Double {
    Double(payload.min ?? 0)
  }

  private var maxValue: Double {
    Double(payload.max ?? 0)
  }

  private var clampedValue: Double {
    min(max(value, minValue), maxValue)
  }

  private var frontSeconds: Int {
    Int(clampedValue.rounded())
  }

  private var behindSeconds: Int {
    Int((maxValue - clampedValue).rounded())
  }

  @ViewBuilder
  private var barView: some View {
    let segments = Int(maxValue - minValue)
    if segments > 0, segments <= 30, minValue == 0 {
      GeometryReader { geo in
        let width = max(1, geo.size.width)
        let segmentSpacing: CGFloat = 4
        let segmentWidth = (width - segmentSpacing * CGFloat(segments - 1)) / CGFloat(segments)
        let selectedCount = max(0, min(segments, frontSeconds))

        HStack(spacing: segmentSpacing) {
          ForEach(1 ... segments, id: \.self) { index in
            RoundedRectangle(cornerRadius: 2)
              .fill(index <= selectedCount ? Color(hex: "0x06BAFF") : Color(hex: "0xCAE4FF"))
              .frame(width: segmentWidth, height: 13)
          }
        }
        .contentShape(Rectangle())
        .gesture(
          DragGesture(minimumDistance: 0)
            .onChanged { gesture in
              let ratio = min(max(gesture.location.x / width, 0), 1)
              let newValue = (ratio * (maxValue - minValue)).rounded()
              value = min(max(newValue, minValue), maxValue)
            }
            .onEnded { _ in
              updateValue()
            }
        )
      }
      .frame(height: 13)
      .padding(.top, 6)
      .disabled(isUpdating)
    } else {
      Slider(value: $value, in: minValue ... maxValue, step: 1) { editing in
        if !editing {
          updateValue()
        }
      }
      .accentColor(Color(hex: "0x06BAFF"))
      .disabled(isUpdating)
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
