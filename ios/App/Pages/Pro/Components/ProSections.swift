import SwiftUI

struct ProPlan: Identifiable, Hashable {
  let id: String
  let name: String
  let price: String
  let period: String
  let isPopular: Bool
}

struct ProPlanButton: View {
  let plan: ProPlan
  let isSelected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ZStack(alignment: .top) {
        VStack(spacing: 0) {
          Text(plan.name)
            .font(.system(size: 14, weight: .black))
            .foregroundColor(isSelected ? .black : .black.opacity(0.40))
          Text(plan.price)
            .font(.system(size: 20, weight: .black))
            .foregroundColor(isSelected ? Color(hex: "#8B5CF6") : .black.opacity(0.40))
            .padding(.top, 12)
          Text(plan.period)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(.black.opacity(0.42))
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 20)
        .background(isSelected ? Color.white : Color.white.opacity(0.45))
        .clipShape(RoundedRectangle(cornerRadius: 26, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 26, style: .continuous)
            .stroke(isSelected ? Color(hex: "#A78BFA") : .clear, lineWidth: 2)
        )
        .shadow(color: isSelected ? Color(hex: "#A78BFA").opacity(0.16) : .clear, radius: 16, x: 0, y: 8)

        if plan.isPopular {
          Text("限时特惠")
            .font(.system(size: 9, weight: .black))
            .foregroundColor(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(LinearGradient(colors: [Color(hex: "#A78BFA"), Color(hex: "#F472B6")], startPoint: .leading, endPoint: .trailing))
            .clipShape(Capsule())
            .shadow(color: Color(hex: "#A78BFA").opacity(0.30), radius: 8, x: 0, y: 4)
            .offset(y: -12)
        }
      }
      .frame(maxWidth: .infinity)
      .padding(.top, 12)
    }
    .buttonStyle(.plain)
  }
}

struct ProFeatureRow: View {
  let symbol: String
  let color: Color
  let title: String
  let desc: String

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: symbol)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(color)
        .frame(width: 34, height: 34)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      VStack(alignment: .leading, spacing: 4) {
        Text(title).font(.system(size: 15, weight: .black)).foregroundColor(.black.opacity(0.80))
        Text(desc).font(.system(size: 12, weight: .bold)).foregroundColor(.black.opacity(0.40))
      }
      Spacer()
    }
    .padding(16)
    .background(Color.white.opacity(0.55))
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
  }
}
