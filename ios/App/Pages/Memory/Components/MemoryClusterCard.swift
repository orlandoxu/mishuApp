import SwiftUI

struct MemoryCluster: Identifiable {
  let id = UUID()
  let title: String
  let symbol: String
  let color: Color
  let items: [String]
}

struct MemoryClusterCard: View {
  let cluster: MemoryCluster

  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      HStack(spacing: 14) {
        Image(systemName: cluster.symbol)
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(cluster.color)
          .frame(width: 44, height: 44)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 3)

        Text(cluster.title)
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(Color.black.opacity(0.85))
      }

      LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10, alignment: .leading)], alignment: .leading, spacing: 10) {
        ForEach(cluster.items, id: \.self) { item in
          Text(item)
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color.black.opacity(0.70))
            .lineLimit(2)
            .padding(.horizontal, 14)
            .padding(.vertical, 11)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white.opacity(0.55))
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
      }
    }
    .padding(22)
    .background(Color.white.opacity(0.38))
    .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 32, style: .continuous)
        .stroke(Color.white.opacity(0.80), lineWidth: 1)
    )
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}
