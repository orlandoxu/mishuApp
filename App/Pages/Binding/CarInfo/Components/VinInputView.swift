import SwiftUI

// DONE-AI: 这个组件还需要优化，有一个很大的问题，就是只能输入最后一个字母。这是非常错误的！不可能只允许修改最后一个字母的
// DONE-AI: 比如我在修改过程中，已经输入了5个字母了，第三个字母错了，现在不允许我点击第三个字母，然后修改第三个字母。这是非常荒谬的，肯定是可以点击前面的字母来修改啊。
// DONE-AI: 同样的问题，会出现在vin编辑页面。因为vin编辑页面完全是已经写好了的vin，如果不允许点击前面的vin来修改，这个体验其实非常差
struct VinInputView: View {
  @Binding var text: String
  @Binding var cursorIndex: Int
  let isFocused: Bool
  let onTap: () -> Void

  /// 17位VIN码
  private let length = 17

  var body: some View {
    VStack(spacing: 8) {
      // 第一排：前9位
      HStack(spacing: 4) {
        ForEach(0 ..< 9, id: \.self) { index in
          Button {
            cursorIndex = normalizedCursorIndex(for: index)
            onTap()
          } label: {
            VinItemView(
              char: char(at: index),
              placeholder: "\(index + 1)",
              isSelected: isFocused && index == cursorIndex
            )
          }
          .buttonStyle(.plain)
        }
      }

      // 第二排：后8位
      HStack(spacing: 4) {
        ForEach(9 ..< 17, id: \.self) { index in
          Button {
            cursorIndex = normalizedCursorIndex(for: index)
            onTap()
          } label: {
            VinItemView(
              char: char(at: index),
              placeholder: "\(index + 1)",
              isSelected: isFocused && index == cursorIndex
            )
          }
          .buttonStyle(.plain)
        }
        VinItemView(char: "", placeholder: "", isSelected: false)
          .hidden()
      }
    }
    .padding(.vertical, 4)
  }

  private func char(at index: Int) -> String {
    if index < text.count {
      let stringIndex = text.index(text.startIndex, offsetBy: index)
      return String(text[stringIndex])
    }
    return ""
  }

  private func normalizedCursorIndex(for index: Int) -> Int {
    min(index, min(text.count, length - 1))
  }
}

private struct VinItemView: View {
  let char: String
  let placeholder: String
  let isSelected: Bool

  var body: some View {
    ZStack {
      // 背景与边框
      RoundedRectangle(cornerRadius: 4)
        .fill(Color.white) // 白色背景
        .overlay(
          RoundedRectangle(cornerRadius: 4)
            .stroke(
              isSelected ? Color.blue : Color(hex: "0xE5E5E5"),
              lineWidth: isSelected ? 2 : 1
            )
        )

      // 文字
      if char.isEmpty {
        Text(placeholder)
          .font(.system(size: 14, weight: .regular))
          .foregroundColor(Color(hex: "0xCCCCCC"))
      } else {
        Text(char)
          .font(.system(size: 18, weight: .medium, design: .monospaced))
          .foregroundColor(Color(hex: "0x111111"))
      }
    }
    .frame(maxWidth: .infinity)
    .aspectRatio(0.75, contentMode: .fit) // 保持宽高比，或者指定高度
    .frame(height: 44) // 固定高度，宽度自适应
  }
}
