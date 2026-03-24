import SwiftUI

struct ModeSwitchItem<Value: Hashable>: Equatable, Hashable {
  let title: String
  let mode: Value
}

struct ModeSwitch<Value: Hashable>: View {
  @Binding var selection: Value

  var items: [ModeSwitchItem<Value>]
  var selectedTextColor: Color = .init(hex: "0x222222")
  var normalTextColor: Color = .init(hex: "0x666666")
  var pickerWidth: CGFloat = 132
  var pickerHeight: CGFloat = 52
  var isEnabled: Bool = true

  private let thumbInset: CGFloat = 3

  private var slotWidth: CGFloat {
    guard items.count > 0 else { return pickerWidth }
    return (pickerWidth - thumbInset * 2) / CGFloat(items.count)
  }

  private var thumbHeight: CGFloat {
    pickerHeight - thumbInset * 2
  }

  private var selectedIndex: Int {
    items.firstIndex(where: { $0.mode == selection }) ?? 0
  }

  var body: some View {
    ZStack(alignment: .leading) {
      Capsule().glass4PickerTrack()

      Capsule()
        .fill(Color.white.opacity(0.92))
        .overlay(Capsule().stroke(Color.white, lineWidth: 1))
        .frame(width: slotWidth, height: thumbHeight)
        .offset(x: CGFloat(selectedIndex) * slotWidth + thumbInset)
        .shadow(color: Color.black.opacity(0.10), radius: 8, x: 0, y: 4)

      HStack(spacing: 0) {
        ForEach(Array(items.enumerated()), id: \.offset) { index, item in
          pickerButton(title: item.title, mode: item.mode, onTap: {
            withAnimation {
              if index > 0, isEnabled == false { return }
              selection = item.mode
            }
          })
        }
      }
    }
    .frame(width: pickerWidth, height: pickerHeight)
  }

  private func pickerButton(title: String, mode: Value, onTap: @escaping () -> Void) -> some View {
    Button {
      onTap()
    } label: {
      Text(title)
        .font(.system(size: 16, weight: .semibold))
        .foregroundColor(selection == mode ? selectedTextColor : normalTextColor)
        .frame(width: slotWidth, height: pickerHeight)
        .contentShape(Rectangle())
    }
    .buttonStyle(.plain)
  }
}
