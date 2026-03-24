import SwiftUI

struct VinKeyboard: View {
  let onSelect: (String) -> Void
  let onDelete: () -> Void
  // let onConfirm: () -> Void // 去掉确定键

  /// 键盘布局
  /// 第一排：数字
  private let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
  /// 第二排：Q-P
  private let row1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
  /// 第三排：A-L
  private let row2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
  /// 第四排：Z-M
  private let row3 = ["Z", "X", "C", "V", "B", "N", "M"]

  /// VIN码不包含 I, O, Q
  private let forbiddenChars: Set<String> = ["I", "O", "Q"]

  var body: some View {
    VStack(spacing: 10) {
      // 第一排：数字
      HStack(spacing: 6) {
        ForEach(numbers, id: \.self) { num in
          KeyButton(
            text: num,
            isDisabled: false,
            action: { onSelect(num) }
          )
        }
      }
      .padding(.horizontal, 4)

      // 第二排
      HStack(spacing: 6) {
        ForEach(row1, id: \.self) { char in
          KeyButton(
            text: char,
            isDisabled: forbiddenChars.contains(char),
            action: { onSelect(char) }
          )
        }
      }
      .padding(.horizontal, 4)

      // 第三排
      HStack(spacing: 6) {
        ForEach(row2, id: \.self) { char in
          KeyButton(
            text: char,
            isDisabled: forbiddenChars.contains(char),
            action: { onSelect(char) }
          )
        }
      }
      .padding(.horizontal, 16)

      // 第四排（包含删除）
      HStack(spacing: 12) {
        Spacer()

        HStack(spacing: 6) {
          ForEach(row3, id: \.self) { char in
            KeyButton(
              text: char,
              isDisabled: forbiddenChars.contains(char),
              action: { onSelect(char) }
            )
          }
        }

        Spacer()

        // 删除按钮
        Button {
          Haptics.impactLight()
          onDelete()
        } label: {
          Image(systemName: "delete.left.fill")
            .font(.system(size: 20))
            .foregroundColor(Color(hex: "0x333333"))
            .frame(width: 44, height: 44)
            .background(Color(hex: "0xACB4C2"))
            .cornerRadius(5)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
      }
      .padding(.horizontal, 4)
    }
    .padding(.top, 8)
    .padding(.bottom, 8 + safeAreaBottom)
    .background(Color(hex: "0xD1D5DB"))
  }
}
