import SwiftUI
import UIKit

struct FoodMemoryCardView: View {
  let memory: FoodMemoryItem
  let onEdit: () -> Void
  let onDelete: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 10) {
        VStack(alignment: .leading, spacing: 6) {
          HStack(spacing: 8) {
            Text(memory.name)
              .font(.system(size: 17, weight: .black))
              .foregroundColor(Color.black.opacity(0.85))
              .lineLimit(1)
            Text(memory.cuisine)
              .font(.system(size: 11, weight: .bold))
              .foregroundColor(Color.blue)
              .padding(.horizontal, 8)
              .padding(.vertical, 3)
              .background(Color.blue.opacity(0.08))
              .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
          }

          HStack(spacing: 2) {
            ForEach(0..<5, id: \.self) { idx in
              Image(systemName: idx < memory.rating ? "star.fill" : "star")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(idx < memory.rating ? Color(hex: "#FB923C") : Color.black.opacity(0.22))
            }
          }

          HStack(spacing: 6) {
            ForEach(memory.features, id: \.self) { feature in
              Text(feature)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(Color.black.opacity(0.50))
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.black.opacity(0.04))
                .clipShape(Capsule())
            }
          }

          Text("¥\(memory.pricePerPerson)/人 · \(memory.lastVisitedText)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color.black.opacity(0.35))
        }

        Spacer()

        Menu {
          Button("编辑") { onEdit() }
          Button("删除", role: .destructive) { onDelete() }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(Color.black.opacity(0.32))
            .frame(width: 30, height: 30)
        }
      }

      HStack(alignment: .top, spacing: 8) {
        Image(systemName: "hand.thumbsup.fill")
          .font(.system(size: 14, weight: .bold))
          .foregroundColor(Color(hex: "#FB923C"))
        Text("必点: \(memory.signatureDishes.joined(separator: " · "))")
          .font(.system(size: 13, weight: .semibold))
          .foregroundColor(Color.black.opacity(0.8))
      }

      if !memory.avoidDishes.isEmpty {
        HStack(alignment: .top, spacing: 8) {
          Image(systemName: "hand.thumbsdown.fill")
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(Color(hex: "#F87171"))
          Text("避雷: \(memory.avoidDishes.joined(separator: " · "))")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.8))
        }
      }

      if !memory.photos.isEmpty {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(Array(memory.photos.enumerated()), id: \.offset) { _, imageValue in
              FoodMemoryPhotoPreview(imageValue: imageValue)
                .frame(width: 122, height: 94)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))
            }
          }
        }
      }

      Text(memory.review)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(Color.black.opacity(0.62))
        .lineSpacing(4)
    }
    .padding(18)
    .background(Color.white.opacity(0.62))
    .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
    .overlay(RoundedRectangle(cornerRadius: 24, style: .continuous).stroke(Color.white.opacity(0.72), lineWidth: 1))
    .shadow(color: Color.black.opacity(0.03), radius: 14, x: 0, y: 4)
  }
}

struct FoodMemoryPhotoPreview: View {
  let imageValue: String

  var body: some View {
    if let data = Data(base64Encoded: imageValue.dataURLPayload),
       let uiImage = UIImage(data: data)
    {
      Image(uiImage: uiImage)
        .resizable()
        .scaledToFill()
    } else if imageValue.hasPrefix("http"), let url = URL(string: imageValue) {
      AsyncImage(url: url) { phase in
        switch phase {
        case let .success(image):
          image.resizable().scaledToFill()
        default:
          Color.black.opacity(0.05)
        }
      }
    } else {
      Image(imageValue)
        .resizable()
        .scaledToFill()
    }
  }
}

private extension String {
  var dataURLPayload: String {
    if let index = firstIndex(of: ","), hasPrefix("data:image") {
      return String(self[self.index(after: index)...])
    }
    return self
  }
}
