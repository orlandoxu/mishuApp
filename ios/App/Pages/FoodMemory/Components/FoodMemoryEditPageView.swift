import PhotosUI
import SwiftUI
import UIKit

struct FoodMemoryEditPageView: View {
  let memory: FoodMemoryItem
  let onSave: (FoodMemoryItem) -> Void

  @Environment(\.dismiss) private var dismiss

  @State private var draft: FoodMemoryItem
  @State private var editingField: EditingField?
  @State private var addingTagField: TagField?
  @State private var newTagValue = ""
  @State private var selectedPhotoItem: PhotosPickerItem?
  @State private var isUploadingPhoto = false

  private enum EditingField: Identifiable {
    case price
    case cuisine

    var id: Int { self == .price ? 0 : 1 }
  }

  enum TagField: String, Identifiable, CaseIterable {
    case features
    case signatureDishes
    case avoidDishes

    var id: String { rawValue }

    var title: String {
      switch self {
      case .features: return "特点标签"
      case .signatureDishes: return "必点菜"
      case .avoidDishes: return "避雷菜"
      }
    }
  }

  private let cuisines = ["川菜", "日料", "法餐", "火锅", "粤菜", "泰餐", "甜点", "小吃", "西餐", "湘菜", "江浙菜", "其他"]

  init(memory: FoodMemoryItem, onSave: @escaping (FoodMemoryItem) -> Void) {
    self.memory = memory
    self.onSave = onSave
    _draft = State(initialValue: memory)
  }

  var body: some View {
    VStack(spacing: 0) {
      topBar
      ScrollView(showsIndicators: false) {
        VStack(alignment: .leading, spacing: 20) {
          TextField("店名", text: $draft.name)
            .font(.system(size: 24, weight: .black))
            .foregroundColor(Color.black.opacity(0.9))

          HStack(spacing: 10) {
            Button {
              editingField = .price
            } label: {
              HStack(spacing: 4) {
                Text("¥")
                  .font(.system(size: 13, weight: .bold))
                  .foregroundColor(Color.black.opacity(0.45))
                Text(draft.pricePerPerson > 0 ? "\(draft.pricePerPerson)" : "--")
                  .font(.system(size: 15, weight: .black))
                  .foregroundColor(Color.black.opacity(0.8))
              }
              .padding(.horizontal, 12)
              .padding(.vertical, 7)
              .background(Color.black.opacity(0.05))
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)

            Button {
              editingField = .cuisine
            } label: {
              HStack(spacing: 4) {
                Text(draft.cuisine.isEmpty ? "选择菜系" : draft.cuisine)
                  .font(.system(size: 15, weight: .black))
                Image(systemName: "chevron.right")
                  .font(.system(size: 11, weight: .bold))
                  .opacity(0.45)
              }
              .foregroundColor(Color(hex: "#FF6B6B"))
              .padding(.horizontal, 12)
              .padding(.vertical, 7)
              .background(Color(hex: "#FF6B6B").opacity(0.12))
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
          }

          TextEditor(text: $draft.review)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color.black.opacity(0.8))
            .frame(minHeight: 120)
            .scrollContentBackground(.hidden)
            .background(Color.clear)

          photoSection
          ratingSection

          tagGroup(field: .features, tags: draft.features)
          tagGroup(field: .signatureDishes, tags: draft.signatureDishes)
          tagGroup(field: .avoidDishes, tags: draft.avoidDishes)
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 30)
      }
    }
    .background(Color.white.ignoresSafeArea())
    .sheet(item: $editingField) { field in
      switch field {
      case .price:
        priceSheet
      case .cuisine:
        cuisineSheet
      }
    }
    .sheet(item: $addingTagField) { field in
      addTagSheet(field: field)
    }
    .onChange(of: selectedPhotoItem) { _ in
      Task { await handlePhotoPick() }
    }
  }

  private var topBar: some View {
    HStack(spacing: 0) {
      Button {
        dismiss()
      } label: {
        Image(systemName: "arrow.left")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(Color.black.opacity(0.7))
          .frame(width: 44, height: 44)
      }
      .buttonStyle(.plain)

      Spacer()

      Text("编辑美食记录")
        .font(.system(size: 17, weight: .black))
        .foregroundColor(Color.black.opacity(0.82))

      Spacer()

      Button("保存") {
        onSave(normalizedDraft)
        dismiss()
      }
      .font(.system(size: 14, weight: .black))
      .foregroundColor(.white)
      .padding(.horizontal, 18)
      .frame(height: 36)
      .background(Color(hex: "#FF6B6B"))
      .clipShape(Capsule())
      .accessibilityIdentifier("food_memory_edit_save")
    }
    .padding(.horizontal, 16)
    .padding(.top, 8)
    .padding(.bottom, 8)
  }

  private var photoSection: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        PhotosPicker(selection: $selectedPhotoItem, matching: .images) {
          VStack(spacing: 4) {
            Image(systemName: isUploadingPhoto ? "hourglass" : "camera")
              .font(.system(size: 24, weight: .medium))
            Text(isUploadingPhoto ? "上传中" : "添加照片")
              .font(.system(size: 12, weight: .bold))
          }
          .foregroundColor(Color.black.opacity(0.32))
          .frame(width: 96, height: 96)
          .background(Color.black.opacity(0.03))
          .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
          .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.black.opacity(0.12), style: StrokeStyle(lineWidth: 1, dash: [6, 4])))
        }
        .buttonStyle(.plain)
        .disabled(isUploadingPhoto)

        ForEach(Array(draft.photos.enumerated()), id: \.offset) { index, imageValue in
          ZStack(alignment: .topTrailing) {
            FoodMemoryPhotoPreview(imageValue: imageValue)
              .frame(width: 96, height: 96)
              .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
              .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).stroke(Color.black.opacity(0.06), lineWidth: 1))

            Button {
              draft.photos.remove(at: index)
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 9, weight: .black))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Color.black.opacity(0.6))
                .clipShape(Circle())
            }
            .offset(x: 6, y: -6)
            .buttonStyle(.plain)
          }
        }
      }
      .padding(.vertical, 2)
    }
  }

  private var ratingSection: some View {
    HStack(spacing: 8) {
      ForEach(1...5, id: \.self) { star in
        Button {
          draft.rating = star
        } label: {
          Image(systemName: star <= draft.rating ? "star.fill" : "star")
            .font(.system(size: 28, weight: .bold))
            .foregroundColor(star <= draft.rating ? Color(hex: "#FB923C") : Color.black.opacity(0.15))
        }
        .buttonStyle(.plain)
      }
    }
  }

  private func tagGroup(field: TagField, tags: [String]) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack {
        Text(field.title)
          .font(.system(size: 14, weight: .black))
          .foregroundColor(Color.black.opacity(0.72))
        Spacer()
        Button("添加") {
          newTagValue = ""
          addingTagField = field
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(Color.black.opacity(0.5))
      }

      if tags.isEmpty {
        Text("暂无")
          .font(.system(size: 12, weight: .medium))
          .foregroundColor(Color.black.opacity(0.35))
      } else {
        FlowWrap(items: tags) { value in
          HStack(spacing: 6) {
            Text(value)
              .font(.system(size: 13, weight: .medium))
            Button {
              removeTag(field: field, value: value)
            } label: {
              Image(systemName: "xmark")
                .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
          }
          .foregroundColor(Color.black.opacity(0.72))
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(Color.black.opacity(0.05))
          .clipShape(Capsule())
        }
      }
    }
  }

  private var priceSheet: some View {
    VStack(spacing: 18) {
      Text("修改人均消费")
        .font(.system(size: 18, weight: .black))
      HStack(spacing: 6) {
        Text("¥")
          .font(.system(size: 20, weight: .black))
          .foregroundColor(Color.black.opacity(0.4))
        TextField("0", value: $draft.pricePerPerson, format: .number)
          .keyboardType(.numberPad)
          .font(.system(size: 32, weight: .black))
          .multilineTextAlignment(.center)
          .frame(width: 140)
      }
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity)
      .background(Color.black.opacity(0.05))
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))

      Button("确定") {
        editingField = nil
      }
      .font(.system(size: 15, weight: .black))
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 48)
      .background(Color(hex: "#FF6B6B"))
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .padding(20)
    .presentationDetents([.height(280)])
  }

  private var cuisineSheet: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 14) {
        Text("选择菜系")
          .font(.system(size: 18, weight: .black))
          .padding(.top, 6)

        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
          ForEach(cuisines, id: \.self) { cuisine in
            Button {
              draft.cuisine = cuisine
              editingField = nil
            } label: {
              Text(cuisine)
                .font(.system(size: 15, weight: .bold))
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(draft.cuisine == cuisine ? Color(hex: "#FF6B6B") : Color(hex: "#F4F5F7"))
                .foregroundColor(draft.cuisine == cuisine ? .white : Color.black.opacity(0.72))
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
          }
        }
      }
      .padding(20)
    }
    .presentationDetents([.height(360)])
  }

  private func addTagSheet(field: TagField) -> some View {
    VStack(spacing: 16) {
      Text("添加\(field.title)")
        .font(.system(size: 18, weight: .black))

      TextField("输入内容", text: $newTagValue)
        .textFieldStyle(.roundedBorder)

      Button("添加") {
        addTag(field: field, value: newTagValue)
        addingTagField = nil
      }
      .font(.system(size: 15, weight: .black))
      .foregroundColor(.white)
      .frame(maxWidth: .infinity)
      .frame(height: 48)
      .background(Color(hex: "#FF6B6B"))
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
    .padding(20)
    .presentationDetents([.height(220)])
  }

  private var normalizedDraft: FoodMemoryItem {
    var item = draft
    item.name = item.name.trimmingCharacters(in: .whitespacesAndNewlines)
    item.review = item.review.trimmingCharacters(in: .whitespacesAndNewlines)
    item.features = item.features.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    item.signatureDishes = item.signatureDishes.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    item.avoidDishes = item.avoidDishes.filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    if item.rating < 1 { item.rating = 1 }
    if item.rating > 5 { item.rating = 5 }
    if item.pricePerPerson < 0 { item.pricePerPerson = 0 }
    return item
  }

  private func addTag(field: TagField, value: String) {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    switch field {
    case .features:
      if !draft.features.contains(trimmed) { draft.features.append(trimmed) }
    case .signatureDishes:
      if !draft.signatureDishes.contains(trimmed) { draft.signatureDishes.append(trimmed) }
    case .avoidDishes:
      if !draft.avoidDishes.contains(trimmed) { draft.avoidDishes.append(trimmed) }
    }
  }

  private func removeTag(field: TagField, value: String) {
    switch field {
    case .features:
      draft.features.removeAll { $0 == value }
    case .signatureDishes:
      draft.signatureDishes.removeAll { $0 == value }
    case .avoidDishes:
      draft.avoidDishes.removeAll { $0 == value }
    }
  }

  @MainActor
  private func handlePhotoPick() async {
    guard let selectedPhotoItem else { return }
    isUploadingPhoto = true
    defer {
      isUploadingPhoto = false
      self.selectedPhotoItem = nil
    }

    do {
      guard let data = try await selectedPhotoItem.loadTransferable(type: Data.self) else { return }
      let uploadedURL = try await FoodMemoryPhotoUploader.shared.upload(data: data)
      draft.photos.append(uploadedURL)
    } catch {
      ToastCenter.shared.show("图片上传失败，请重试")
    }
  }
}

private struct FlowWrap<Item: Hashable, Content: View>: View {
  let items: [Item]
  let content: (Item) -> Content

  init(items: [Item], @ViewBuilder content: @escaping (Item) -> Content) {
    self.items = items
    self.content = content
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
        HStack(spacing: 8) {
          ForEach(row, id: \.self) { item in
            content(item)
          }
          Spacer(minLength: 0)
        }
      }
    }
  }

  private var rows: [[Item]] {
    guard !items.isEmpty else { return [] }
    var rowItems: [[Item]] = [[]]
    for item in items {
      if rowItems[rowItems.count - 1].count >= 4 {
        rowItems.append([item])
      } else {
        rowItems[rowItems.count - 1].append(item)
      }
    }
    return rowItems
  }
}

actor FoodMemoryPhotoUploader {
  static let shared = FoodMemoryPhotoUploader()

  func upload(data: Data) async throws -> String {
    let maxBytes = 2_000_000
    let bodyData: Data
    if data.count > maxBytes, let image = UIImage(data: data), let compressed = image.jpegData(compressionQuality: 0.7) {
      bodyData = compressed
    } else {
      bodyData = data
    }
    return "data:image/jpeg;base64,\(bodyData.base64EncodedString())"
  }
}
