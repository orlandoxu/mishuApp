import SwiftUI

struct LicensePlateInputView: View {
  let chars: [String] // 固定长度 8
  let currentIndex: Int
  let onTapIndex: (Int) -> Void
  
  var body: some View {
    HStack(spacing: 6) {
      // 省份
      PlateItemView(
        char: chars[0],
        isSelected: currentIndex == 0,
        placeholder: "省",
        onTap: { onTapIndex(0) }
      )
      
      // 城市代码
      PlateItemView(
        char: chars[1],
        isSelected: currentIndex == 1,
        placeholder: "A",
        onTap: { onTapIndex(1) }
      )
      
      // 点
      Circle()
        .fill(Color(hex: "0xCCCCCC"))
        .frame(width: 4, height: 4)
        .padding(.horizontal, 2)
      
      // 号码 5位
      ForEach(2..<7) { index in
        PlateItemView(
          char: chars[index],
          isSelected: currentIndex == index,
          placeholder: "",
          onTap: { onTapIndex(index) }
        )
      }
      
      // 新能源位
      NewEnergyItemView(
        char: chars[7],
        isSelected: currentIndex == 7,
        onTap: { onTapIndex(7) }
      )
    }
  }
}

// 普通输入格
private struct PlateItemView: View {
  let char: String
  let isSelected: Bool
  let placeholder: String
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      ZStack {
        // 背景与边框
        RoundedRectangle(cornerRadius: 4)
          .fill(Color.white)
          .overlay(
            RoundedRectangle(cornerRadius: 4)
              .stroke(
                isSelected ? Color.blue : Color(hex: "0xE5E5E5"),
                lineWidth: isSelected ? 2 : 1
              )
          )
        
        // 文字
        if !char.isEmpty {
          Text(char)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Color(hex: "0x111111"))
        } else if !placeholder.isEmpty && !isSelected {
          // 占位符（非选中状态下显示，或者选中也显示？通常选中时不显示占位符）
          // 截图上好像有 A 的占位符
          Text(placeholder)
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(Color(hex: "0xCCCCCC"))
        }
        
        // 光标（仅选中且无内容时显示？或者选中时一直显示？自定义键盘通常不需要光标闪烁，只需要高亮边框）
      }
      .frame(width: 36, height: 48) // 根据屏幕宽度自适应，这里先给固定值或 Flexible
    }
    .buttonStyle(.plain)
  }
}

// 新能源输入格
private struct NewEnergyItemView: View {
  let char: String
  let isSelected: Bool
  let onTap: () -> Void
  
  var body: some View {
    Button(action: onTap) {
      ZStack {
        // 背景与边框
        if char.isEmpty {
            // 空状态：显示“新”，绿色虚线框（或实线）
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(hex: "0xF0FDF4")) // 浅绿背景
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isSelected ? Color.blue : Color(hex: "0x52C41A"), // 选中变蓝，否则绿
                            style: StrokeStyle(lineWidth: isSelected ? 2 : 1, dash: isSelected ? [] : [4, 2])
                        )
                )
            
            Text("新")
                .font(.system(size: 14))
                .foregroundColor(Color(hex: "0x52C41A"))
        } else {
            // 有值状态：同普通格子
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(
                            isSelected ? Color.blue : Color(hex: "0xE5E5E5"),
                            lineWidth: isSelected ? 2 : 1
                        )
                )
            
            Text(char)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(Color(hex: "0x111111"))
        }
      }
      .frame(width: 36, height: 48)
    }
    .buttonStyle(.plain)
  }
}
