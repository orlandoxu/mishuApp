import SwiftUI

struct MoneyTransaction: Identifiable {
  let id: String
  let type: String
  let amount: Int
  let category: String
  let date: String
  let note: String
}

struct MoneyBudgetCard: View {
  let mode: String
  let progress: Double
  let limit: Int
  let onToggle: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      HStack {
        Text(mode == "expense" ? "本周预算" : "收入目标")
          .font(.system(size: 18, weight: .black))
        Spacer()
        Button(mode == "expense" ? "切到收入" : "切到支出", action: onToggle)
          .font(.system(size: 12, weight: .bold))
          .foregroundColor(.black.opacity(0.52))
      }

      Text("¥\(limit)")
        .font(.system(size: 38, weight: .black))
        .foregroundColor(Color.black.opacity(0.84))

      ProgressView(value: min(progress, 1))
        .tint(mode == "expense" ? Color(hex: "#FF7AA2") : Color(hex: "#44C986"))
    }
    .padding(22)
    .background(Color.white)
    .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
  }
}

struct MoneyStatCards: View {
  let expense: Int
  let income: Int

  var body: some View {
    HStack(spacing: 12) {
      stat(title: "支出", value: expense, color: Color(hex: "#FF7AA2"))
      stat(title: "收入", value: income, color: Color(hex: "#44C986"))
    }
  }

  private func stat(title: String, value: Int, color: Color) -> some View {
    ZStack(alignment: .topLeading) {
      Image(title == "支出" ? "img_money_income" : "img_money_pay")
        .resizable()
        .scaledToFill()

      VStack(alignment: .leading, spacing: 10) {
        HStack(spacing: 4) {
          Image(systemName: title == "支出" ? "arrow.down.right" : "arrow.up.right")
            .font(.system(size: 11, weight: .black))
          Text(title == "支出" ? "支出总计" : "收入总计")
            .font(.system(size: 10, weight: .black))
            .tracking(0.8)
        }
        .foregroundColor(color)

        Text("¥\(value)")
          .font(.system(size: 26, weight: .black))
          .foregroundColor(.black)
          .tracking(-0.5)
      }
      .padding(18)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .aspectRatio(24.0 / 15.0, contentMode: .fit)
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white.opacity(0.50), lineWidth: 1)
    )
  }
}

struct MoneyTransactionList: View {
  let transactions: [MoneyTransaction]

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("流水明细")
        .font(.system(size: 18, weight: .black))
      ForEach(transactions) { item in
        HStack(spacing: 12) {
          Image(systemName: item.type == "income" ? "plus.circle.fill" : "minus.circle.fill")
            .foregroundColor(item.type == "income" ? Color(hex: "#44C986") : Color(hex: "#FF7AA2"))
          VStack(alignment: .leading, spacing: 4) {
            Text(item.note).font(.system(size: 15, weight: .bold))
            Text("\(item.category) · \(item.date)").font(.system(size: 12, weight: .medium)).foregroundColor(.black.opacity(0.38))
          }
          Spacer()
          Text("\(item.type == "income" ? "+" : "-")¥\(item.amount)")
            .font(.system(size: 16, weight: .black))
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
      }
    }
  }
}
