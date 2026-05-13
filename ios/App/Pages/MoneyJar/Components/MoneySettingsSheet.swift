import SwiftUI

struct MoneySettingsSheet: View {
  @Binding var budgetMode: String
  @Binding var budgetLimit: Int
  @Binding var incomeGoal: Int

  private var currentLimit: Int {
    budgetMode == "expense" ? budgetLimit : incomeGoal
  }

  private var limitStep: Int {
    switch currentLimit {
    case ..<100:
      return 10
    case ..<1_000:
      return 50
    case ..<10_000:
      return 500
    default:
      var upperBound = 100_000
      var step = 5_000
      while currentLimit >= upperBound {
        upperBound *= 10
        step *= 10
      }
      return step
    }
  }

  var body: some View {
    VStack(spacing: 0) {
      VStack(alignment: .leading, spacing: 32) {
        VStack(alignment: .leading, spacing: 16) {
          Text("显示模式")
            .font(.system(size: 17, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
            .padding(.leading, 4)

          HStack(spacing: 4) {
            modeButton(title: "支出预算", mode: "expense")
            modeButton(title: "收入目标", mode: "income")
          }
          .padding(6)
          .background(Color(hex: "#F8F9FB"))
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }

        VStack(alignment: .leading, spacing: 18) {
          Text(budgetMode == "expense" ? "单周支出上限" : "单周收入目标")
            .font(.system(size: 17, weight: .black))
            .foregroundColor(Color.black.opacity(0.80))
            .padding(.leading, 4)

          HStack {
            stepButton(symbol: "minus") {
              updateLimit(max(0, currentLimit - limitStep))
            }

            Spacer()

            HStack(alignment: .firstTextBaseline, spacing: 6) {
              Text("¥")
                .font(.system(size: 34, weight: .black))
                .foregroundColor(Color.black.opacity(0.90))
                .layoutPriority(1)
              TextField("", text: limitText)
                .keyboardType(.numberPad)
                .multilineTextAlignment(.leading)
                .font(.system(size: 34, weight: .black))
                .foregroundColor(Color.black.opacity(0.90))
                .tracking(-1.2)
                .frame(width: 138, alignment: .leading)
                .textFieldStyle(.plain)
                .background(Color.clear)
            }
            .frame(width: 184, alignment: .center)

            Spacer()

            stepButton(symbol: "plus") {
              updateLimit(currentLimit + limitStep)
            }
          }
        }
      }

      Button {
        closeSheet()
      } label: {
        Text("保存并返回")
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 64)
          .background(Color.black)
          .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      }
      .buttonStyle(.plain)
      .padding(.top, 40)
    }
    .padding(.horizontal, 32)
    .padding(.vertical, 32)
    .frame(maxWidth: 342)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .shadow(color: Color.black.opacity(0.18), radius: 36, x: 0, y: 12)
  }

  private var limitText: Binding<String> {
    Binding(
      get: { "\(currentLimit)" },
      set: { newValue in
        let digits = newValue.filter(\.isNumber)
        updateLimit(Int(digits) ?? 0)
      }
    )
  }

  private func modeButton(title: String, mode: String) -> some View {
    Button {
      budgetMode = mode
    } label: {
      Text(title)
        .font(.system(size: 14, weight: .black))
        .foregroundColor(budgetMode == mode ? .black : Color.black.opacity(0.20))
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(budgetMode == mode ? Color.white : Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .shadow(color: budgetMode == mode ? Color.black.opacity(0.04) : .clear, radius: 4, x: 0, y: 2)
    }
    .buttonStyle(.plain)
  }

  private func stepButton(symbol: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: symbol)
        .font(.system(size: 24, weight: .semibold))
        .foregroundColor(Color.black.opacity(0.60))
        .frame(width: 50, height: 50)
        .background(Color(hex: "#F8F9FB"))
        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 15, style: .continuous)
            .stroke(Color.black.opacity(0.02), lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  private func updateLimit(_ value: Int) {
    if budgetMode == "expense" {
      budgetLimit = value
    } else {
      incomeGoal = value
    }
  }

  private func closeSheet() {
    BottomSheetCenter.shared.hide()
  }
}
