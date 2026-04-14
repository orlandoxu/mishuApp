import SwiftUI

// MARK: - 键盘类型

enum LicenseKeyboardType {
  case province
  case alphanumeric
}

// DONE-AI: 已抽取到 Utils/Extensions/UIApplication+dismissKeyboard.swift，供全局复用

// MARK: - 省份键盘

struct ProvinceKeyboard: View {
  let onSelect: (String) -> Void

  /// 省份列表（按常见输入法布局或拼音排序，这里沿用原代码中的顺序或优化布局）
  /// 按照通常习惯，分为几行显示
  private let provinces: [String] = [
    "京", "津", "沪", "渝", "冀", "豫", "云", "辽", "黑", "湘",
    "皖", "鲁", "新", "苏", "浙", "赣", "鄂", "桂", "甘", "晋",
    "蒙", "陕", "吉", "闽", "贵", "粤", "青", "藏", "川", "宁",
    "琼", "使", "领", "警", "学", "港", "澳",
  ]

  var body: some View {
    VStack(spacing: 12) {
      // 标题栏或工具栏（可选）
      // 这里直接放键盘内容

      let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 8) // 8列

      LazyVGrid(columns: columns, spacing: 8) {
        ForEach(provinces, id: \.self) { province in
          Button {
            Haptics.impactLight()
            onSelect(province)
          } label: {
            Text(province)
              .font(.system(size: 18, weight: .medium))
              .foregroundColor(Color(hex: "0x333333"))
              .frame(height: 44)
              .frame(maxWidth: .infinity)
              .background(Color.white)
              .cornerRadius(5)
              .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
          }
        }
      }
      .padding(.horizontal, 4)

      // 底部操作栏（清空/删除）
      // HStack {
      //   Spacer()
      //   Button {
      //     onDelete()
      //   } label: {
      //     Image(systemName: "delete.left")
      //       .font(.system(size: 20))
      //       .foregroundColor(Color(hex: "0x333333"))
      //       .frame(width: 80, height: 44)
      //       .background(Color.white)
      //       .cornerRadius(5)
      //       .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
      //   }
      // }
      // .padding(.horizontal, 4)
      // .padding(.top, 4)
    }
    .padding(.top, 8)
    .padding(.bottom, 8 + safeAreaBottom)
    .ignoresSafeArea()
    .background(Color(hex: "0xD1D5DB")) // 键盘背景色
  }
}

// MARK: - 数字字母键盘

struct AlphanumericKeyboard: View {
  let isFirstLetter: Bool // 是否是第一位字母（省份后的一位），不能是数字
  let onSelect: (String) -> Void
  let onDelete: () -> Void
  let onClear: () -> Void // 清空

  /// 键盘布局
  /// 第一排：数字
  private let numbers = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "0"]
  /// 第二排：Q-P
  private let row1 = ["Q", "W", "E", "R", "T", "Y", "U", "I", "O", "P"]
  /// 第三排：A-L
  private let row2 = ["A", "S", "D", "F", "G", "H", "J", "K", "L"]
  /// 第四排：Z-M
  private let row3 = ["Z", "X", "C", "V", "B", "N", "M"]

  /// 不允许输入的字符（I, O）
  private let forbiddenChars: Set<String> = ["I", "O"]

  var body: some View {
    VStack(spacing: 10) {
      // 第一排：数字（如果是第一位字母，则禁用）
      HStack(spacing: 6) {
        ForEach(numbers, id: \.self) { num in
          KeyButton(
            text: num,
            isDisabled: isFirstLetter,
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
      .padding(.horizontal, 16) // 稍微缩进

      // 第四排（包含删除）
      HStack(spacing: 12) {
        // 清空按钮
        // 如果不需要清空，可以用 Spacer
        // Button("清空") { onClear() } ...
        // 这里暂时不放清空，或者放左下角

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
            .background(Color(hex: "0xACB4C2")) // 功能键背景深一点
            .cornerRadius(5)
            .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
        }
      }
      .padding(.horizontal, 4)
    }
    .padding(.top, 8)
    .padding(.bottom, 8 + safeAreaBottom)
    .ignoresSafeArea()
    .background(Color(hex: "0xD1D5DB"))
  }
}

/// 单个按键视图
struct KeyButton: View {
  let text: String
  let isDisabled: Bool
  let action: () -> Void

  var body: some View {
    Button {
      if !isDisabled {
        Haptics.impactLight()
      }
      action()
    } label: {
      Text(text)
        .font(.system(size: 20, weight: .medium))
        .foregroundColor(isDisabled ? Color.gray.opacity(0.5) : Color(hex: "0x111111"))
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(isDisabled ? Color(hex: "0xE0E0E0") : Color.white)
        .cornerRadius(5)
        .shadow(color: Color.black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
    .disabled(isDisabled)
    .buttonStyle(.plain) // 避免默认样式干扰
  }
}
