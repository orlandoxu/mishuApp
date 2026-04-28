import SwiftUI

struct MoneyTransaction: Identifiable {
  let id: String
  let type: String
  let amount: Int
  let category: String
  let date: String
  let note: String
}

struct MoneyWeekSelector: View {
  let title: String
  let canGoNext: Bool
  let onPrevious: () -> Void
  let onNext: () -> Void

  var body: some View {
    HStack {
      Button(action: onPrevious) {
        Image(systemName: "chevron.left")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color.black.opacity(0.24))
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)

      Spacer()

      HStack(spacing: 12) {
        Image(systemName: "calendar")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color.black.opacity(0.80))
        Text(title)
          .font(.system(size: 15, weight: .black))
          .foregroundColor(Color.black.opacity(0.70))
      }

      Spacer()

      Button(action: onNext) {
        Image(systemName: "chevron.right")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color.black.opacity(canGoNext ? 0.24 : 0.10))
          .frame(width: 34, height: 34)
      }
      .buttonStyle(.plain)
      .disabled(!canGoNext)
    }
    .padding(.horizontal, 8)
    .padding(.vertical, 12)
  }
}

struct MoneyBudgetCard: View {
  let mode: String
  let progress: Double
  let limit: Int
  let onToggle: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      ZStack(alignment: .top) {
        SemiCircleGauge(progress: min(max(progress, 0), 1), color: gaugeColor)
          .frame(width: 240, height: 135)

        VStack(spacing: 4) {
          Text(mode == "expense" ? "支出预算" : "收入目标")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color.black.opacity(0.20))
            .tracking(2.2)
            .textCase(.uppercase)
            .padding(.leading, 8)

          Text("¥\(limit)")
            .font(.system(size: 36, weight: .black))
            .foregroundColor(.black)
            .tracking(-1.2)
            .minimumScaleFactor(0.72)
            .lineLimit(1)
        }
        .padding(.top, 62)
      }

      HStack(spacing: 8) {
        HStack(spacing: 8) {
          Circle()
            .fill(Color.black.opacity(0.02))
            .frame(width: 24, height: 24)
            .overlay(
              Image(systemName: "bell.fill")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.black.opacity(0.20))
            )
          Text("本周余额充值哦！")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(Color.black.opacity(0.30))
        }

        Button(action: onToggle) {
          Text(mode == "expense" ? "收入目标" : "支出预算")
            .font(.system(size: 12, weight: .black))
            .foregroundColor(mode == "expense" ? Color(hex: "#43E6C1") : Color(hex: "#FFA3B1"))
        }
        .buttonStyle(.plain)
      }
      .padding(.top, 18)
    }
    .frame(maxWidth: .infinity)
  }

  private var gaugeColor: Color {
    mode == "expense" ? Color(hex: "#FFA3B1") : Color(hex: "#43E6C1")
  }
}

private struct SemiCircleGauge: View {
  let progress: Double
  let color: Color

  var body: some View {
    ZStack {
      GaugeArc(progress: 1)
        .stroke(Color(hex: "#F2F4F7"), style: StrokeStyle(lineWidth: 14, lineCap: .round))
      GaugeArc(progress: progress)
        .stroke(color, style: StrokeStyle(lineWidth: 14, lineCap: .round))
        .animation(.easeOut(duration: 0.8), value: progress)
    }
  }
}

private struct GaugeArc: Shape {
  let progress: Double

  func path(in rect: CGRect) -> Path {
    var path = Path()
    let center = CGPoint(x: rect.midX, y: rect.maxY - 15)
    let radius = min(rect.width / 2 - 20, rect.height - 20)
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .degrees(180),
      endAngle: .degrees(180 + 180 * progress),
      clockwise: false
    )
    return path
  }
}

struct MoneyStatCards: View {
  let expense: Int
  let income: Int

  var body: some View {
    HStack(spacing: 16) {
      stat(title: "支出总计", value: expense, imageName: "img_money_income", symbol: "arrow.down.right", color: Color(hex: "#FF5778"))
      stat(title: "收入总计", value: income, imageName: "img_money_pay", symbol: "arrow.up.right", color: Color(hex: "#00D084"))
    }
  }

  private func stat(title: String, value: Int, imageName: String, symbol: String, color: Color) -> some View {
    ZStack(alignment: .topLeading) {
      Image(imageName)
        .resizable()
        .scaledToFill()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()

      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 4) {
          Image(systemName: symbol)
            .font(.system(size: 12, weight: .black))
          Text(title)
            .font(.system(size: 10, weight: .black))
            .tracking(0.8)
            .textCase(.uppercase)
        }
        .foregroundColor(color)

        Text("¥\(value)")
          .font(.system(size: 26, weight: .black))
          .foregroundColor(.black)
          .tracking(-0.8)
      }
      .padding(.top, 24)
      .padding(.horizontal, 20)
    }
    .aspectRatio(24.0 / 15.0, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white.opacity(0.50), lineWidth: 1)
    )
    .shadow(color: color.opacity(0.10), radius: 32, x: 0, y: 12)
  }
}

struct MoneyTransactionList: View {
  let transactions: [MoneyTransaction]

  var body: some View {
    VStack(spacing: 16) {
      HStack {
        Text("流水记录")
          .font(.system(size: 17, weight: .black))
          .foregroundColor(Color.black.opacity(0.90))
        Spacer()
        HStack(spacing: 4) {
          Text("查看详情")
          Image(systemName: "chevron.right")
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(Color.black.opacity(0.30))
      }
      .padding(.horizontal, 4)

      VStack(spacing: 12) {
        ForEach(transactions) { item in
          HStack(spacing: 20) {
            Text(transactionEmoji(for: item.category))
              .font(.system(size: 24))
              .frame(width: 56, height: 56)
              .background(transactionBackground(for: item.category))
              .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))

            VStack(alignment: .leading, spacing: 5) {
              Text(item.category)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(Color.black.opacity(0.80))
              Text("\(item.date) · \(item.note)")
                .font(.system(size: 13, weight: .black))
                .foregroundColor(Color.black.opacity(0.20))
                .tracking(-0.2)
            }

            Spacer()

            Text("\(item.type == "expense" ? "-" : "+")\(item.amount)")
              .font(.system(size: 20, weight: .black))
              .foregroundColor(item.type == "expense" ? Color.black.opacity(0.90) : Color(hex: "#00D084"))
          }
          .padding(20)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 28, style: .continuous)
              .stroke(Color.black.opacity(0.01), lineWidth: 1)
          )
          .shadow(color: Color.black.opacity(0.02), radius: 24, x: 0, y: 8)
        }
      }
    }
    .padding(.top, 4)
  }

  private func transactionEmoji(for category: String) -> String {
    switch category {
    case "餐饮":
      return "🍔"
    case "交通":
      return "🚌"
    default:
      return "📦"
    }
  }

  private func transactionBackground(for category: String) -> Color {
    switch category {
    case "餐饮":
      return Color(hex: "#FFF2F4")
    case "交通":
      return Color(hex: "#F2F8FF")
    default:
      return Color.black.opacity(0.03)
    }
  }
}

struct MoneySettingsSheet: View {
  @Binding var isOpen: Bool
  @Binding var budgetMode: String
  @Binding var budgetLimit: Int
  @Binding var incomeGoal: Int

  private var currentLimit: Int {
    budgetMode == "expense" ? budgetLimit : incomeGoal
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      Color.black.opacity(0.20)
        .ignoresSafeArea()
        .onTapGesture { isOpen = false }

      VStack(spacing: 0) {
        Capsule()
          .fill(Color.black.opacity(0.05))
          .frame(width: 48, height: 6)
          .padding(.bottom, 30)

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
                updateLimit(max(0, currentLimit - 50))
              }

              Spacer()

              VStack(spacing: 4) {
                Text(budgetMode == "expense" ? "建议 ¥500" : "建议 ¥1000")
                  .font(.system(size: 13, weight: .bold))
                  .foregroundColor(Color.black.opacity(0.30))
                Text("¥ \(currentLimit)")
                  .font(.system(size: 40, weight: .black))
                  .foregroundColor(Color.black.opacity(0.90))
                  .tracking(-1.2)
              }

              Spacer()

              stepButton(symbol: "plus") {
                updateLimit(currentLimit + 50)
              }
            }
          }
        }

        Button {
          isOpen = false
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
      .padding(.top, 10)
      .padding(.bottom, 48)
      .background(Color.white)
      .clipShape(RoundedCorner(radius: 40, corners: [.topLeft, .topRight]))
      .shadow(color: Color.black.opacity(0.18), radius: 36, x: 0, y: -8)
    }
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
        .frame(width: 56, height: 56)
        .background(Color(hex: "#F8F9FB"))
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
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
}
