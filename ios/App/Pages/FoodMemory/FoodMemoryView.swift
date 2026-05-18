import SwiftUI
import MapKit

private struct FoodMemory: Identifiable, Hashable {
  let id: String
  var name: String
  var cuisine: String
  var pricePerPerson: Int
  var lastVisited: String
  var rating: Int
  var features: [String]
  var signatureDishes: [String]
  var avoidDishes: [String]
  var review: String
  var photos: [String]
  var lat: Double
  var lng: Double
  var address: String
  var visitedAtMs: Int64
}

private struct RemoteFoodMemoryDTO: Codable, Identifiable {
  let id: String
  let name: String
  let category: String
  let pricePerPerson: Int
  let visitedAt: Int64
  let rating: Int
  let features: [String]
  let signatureDishes: [String]
  let avoidDishes: [String]
  let review: String
  let photos: [String]
  let lat: Double
  let lng: Double
  let address: String
}

private struct RemoteFoodMemoryListDTO: Codable {
  let items: [RemoteFoodMemoryDTO]
  let total: Int
  let page: Int
  let pageSize: Int
}

private struct RemoteFoodMonthDTO: Codable {
  let month: String
  let count: Int
}

private struct RemoteFoodMonthListDTO: Codable {
  let items: [RemoteFoodMonthDTO]
}

private struct FoodDeleteBody: Encodable { let id: String }
private struct FoodListBody: Encodable {
  let category: String
  let month: String
  let page: Int
  let pageSize: Int
}
private struct FoodCreateBody: Encodable {
  let name: String
  let category: String
  let pricePerPerson: Int
  let visitedAt: Int64
  let rating: Int
  let features: [String]
  let signatureDishes: [String]
  let avoidDishes: [String]
  let review: String
  let photos: [String]
  let lat: Double
  let lng: Double
  let address: String
}
private struct FoodUpdateBody: Encodable {
  let id: String
  let name: String
  let category: String
  let pricePerPerson: Int
  let visitedAt: Int64
  let rating: Int
  let features: [String]
  let signatureDishes: [String]
  let avoidDishes: [String]
  let review: String
  let photos: [String]
  let lat: Double
  let lng: Double
  let address: String
}

private struct FoodMapPinPosition {
  let top: CGFloat
  let left: CGFloat
  let colors: [Color]
}

private enum FoodMemoryMock {
  static let items: [FoodMemory] = [
    FoodMemory(id: "1", name: "地道川菜馆", cuisine: "川菜", pricePerPerson: 100, lastVisited: "2026/04/20", rating: 5, features: ["正宗", "环境雅致", "服务周到"], signatureDishes: ["麻婆豆腐", "水煮牛肉"], avoidDishes: ["担担面"], review: "因为一起吃到了正宗的麻婆豆腐，开启了第一次长谈。味道真的非常地道，辣味很正宗。", photos: ["img_card_food", "img_card_memory"], lat: 31.2304, lng: 121.4737, address: "上海市黄浦区", visitedAtMs: 1776614400000),
    FoodMemory(id: "2", name: "深夜居酒屋", cuisine: "日料", pricePerPerson: 250, lastVisited: "2026/03/15", rating: 4, features: ["氛围好", "深夜食堂"], signatureDishes: ["烤鸡肉串", "清酒"], avoidDishes: ["刺身拼盘"], review: "特别的烤鸡肉串，气氛很好，安静且深入的交流。是一个很好的闲聊之处。", photos: ["img_card_love", "img_card_friends"], lat: 31.2280, lng: 121.4820, address: "上海市静安区", visitedAtMs: 1773532800000),
    FoodMemory(id: "3", name: "法式浪漫庄园", cuisine: "法餐", pricePerPerson: 800, lastVisited: "2026/01/10", rating: 5, features: ["奢华", "约会圣地"], signatureDishes: ["惠灵顿牛排", "红酒炖鹅肝"], avoidDishes: [], review: "纪念日去的地方，环境太棒了，体验感极佳。", photos: ["img_main_ad_background"], lat: 31.2400, lng: 121.4600, address: "上海市徐汇区", visitedAtMs: 1768003200000),
    FoodMemory(id: "4", name: "老北京铜锅涮羊肉", cuisine: "火锅", pricePerPerson: 150, lastVisited: "2026/05/01", rating: 3, features: ["接地气", "适合多人"], signatureDishes: ["手切羊肉", "糖蒜"], avoidDishes: ["烧饼"], review: "还可以，就是人太多了，有点吵闹，烧饼没想象中好吃。", photos: [], lat: 31.2190, lng: 121.5000, address: "上海市虹口区", visitedAtMs: 1777593600000),
    FoodMemory(id: "5", name: "经典粤式茶楼", cuisine: "粤菜", pricePerPerson: 120, lastVisited: "2026/05/05", rating: 5, features: ["早茶", "地道"], signatureDishes: ["虾饺", "红米肠"], avoidDishes: ["凤爪"], review: "早茶就是要够早，虾饺饱满，红米肠口感绝了。", photos: ["img_card_child"], lat: 31.2360, lng: 121.4680, address: "上海市长宁区", visitedAtMs: 1777939200000),
    FoodMemory(id: "6", name: "热带雨林泰餐", cuisine: "东南亚菜", pricePerPerson: 180, lastVisited: "2026/04/10", rating: 4, features: ["酸辣", "香料浓郁"], signatureDishes: ["冬阴功汤", "咖喱蟹"], avoidDishes: ["生春卷"], review: "味道很正，很有泰国的味道，辣得很过瘾。", photos: [], lat: 31.2500, lng: 121.4750, address: "上海市普陀区", visitedAtMs: 1775779200000),
    FoodMemory(id: "7", name: "街角甜品屋", cuisine: "甜点", pricePerPerson: 60, lastVisited: "2026/05/10", rating: 5, features: ["精致", "网红打卡"], signatureDishes: ["提拉米苏", "抹茶千层"], avoidDishes: ["拿破仑"], review: "周末下午茶的好去处，千层蛋糕一点都不腻。", photos: [], lat: 31.2260, lng: 121.4620, address: "上海市黄浦区", visitedAtMs: 1778371200000),
    FoodMemory(id: "8", name: "老巷子小吃摊", cuisine: "小吃", pricePerPerson: 30, lastVisited: "2026/05/12", rating: 4, features: ["便宜", "烟火气"], signatureDishes: ["臭豆腐", "炸串"], avoidDishes: [], review: "吃的就是那个味道，很有小时候的感觉。", photos: [], lat: 31.2330, lng: 121.4900, address: "上海市杨浦区", visitedAtMs: 1778544000000)
  ]

  static let mapPinPositions: [String: FoodMapPinPosition] = [
    "1": .init(top: 0.35, left: 0.25, colors: [Color(hex: "#FB923C"), Color(hex: "#EF4444")]),
    "2": .init(top: 0.45, left: 0.60, colors: [Color(hex: "#60A5FA"), Color(hex: "#6366F1")]),
    "3": .init(top: 0.65, left: 0.30, colors: [Color(hex: "#E879F9"), Color(hex: "#EC4899")]),
    "4": .init(top: 0.25, left: 0.70, colors: [Color(hex: "#FB923C"), Color(hex: "#F59E0B")]),
    "5": .init(top: 0.75, left: 0.55, colors: [Color(hex: "#34D399"), Color(hex: "#14B8A6")]),
    "6": .init(top: 0.70, left: 0.80, colors: [Color(hex: "#FCD34D"), Color(hex: "#FB923C")]),
    "7": .init(top: 0.45, left: 0.40, colors: [Color(hex: "#F9A8D4"), Color(hex: "#FB7185")]),
    "8": .init(top: 0.85, left: 0.25, colors: [Color(hex: "#93C5FD"), Color(hex: "#22D3EE")])
  ]
}

struct FoodMemoryView: View {
  private enum ViewMode { case list, map }

  @State private var memories = FoodMemoryMock.items
  @State private var selectedCategory = "全部"
  @State private var activeMenuId: String?
  @State private var editingMemoryId: String?
  @State private var deletingId: String?
  @State private var viewMode: ViewMode = .list
  @State private var selectedMapPinId: String?
  @State private var selectedMonth: String?
  @State private var monthStats: [String: Int] = [:]
  @State private var mapRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
  )

  private var categories: [String] {
    ["全部"] + Set(memories.map(\.cuisine)).sorted()
  }

  private var months: [String] {
    if monthStats.isEmpty {
      return ["2026/06", "2026/05", "2026/04", "2026/03", "2026/02", "2026/01"]
    }
    return monthStats.keys.sorted(by: >)
  }

  private var filteredByCategory: [FoodMemory] {
    selectedCategory == "全部" ? memories : memories.filter { $0.cuisine == selectedCategory }
  }

  private var displayedMemories: [FoodMemory] {
    guard let selectedMonth else { return filteredByCategory }
    return filteredByCategory.filter { $0.lastVisited.hasPrefix(selectedMonth) }
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#F8F9FB").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "美食记忆") {
          Button {
            // v1 UI mock: add a placeholder memory.
            addMockMemory()
          } label: {
            Image(systemName: "plus")
              .font(.system(size: 21, weight: .bold))
              .foregroundColor(Color(hex: "#FF6B6B"))
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_add_button")
        }

        filterBar

        contentView
      }

      if let editingMemoryId,
         let memory = memories.first(where: { $0.id == editingMemoryId }) {
        FoodMemoryEditSheet(memory: memory, onClose: { self.editingMemoryId = nil }, onSave: updateMemory)
      }

      if deletingId != nil {
        FoodDeleteConfirm(
          onCancel: { deletingId = nil },
          onDelete: {
            guard let deletingId else { return }
            Task {
              let deleted: Empty? = await APIClient().postRequest(
                "/food-memory/delete",
                FoodDeleteBody(id: deletingId),
                true,
                true
              )
              let success = deleted != nil
              await MainActor.run {
                if success {
                  memories.removeAll { $0.id == deletingId }
                  selectedMapPinId = selectedMapPinId == deletingId ? nil : selectedMapPinId
                } else {
                  ToastCenter.shared.show("删除失败，请稍后重试")
                }
                self.deletingId = nil
              }
            }
          }
        )
      }
    }
    .accessibilityIdentifier("food_memory_root")
    .task {
      await loadRemoteData()
    }
    .onChange(of: selectedCategory) { _ in
      Task { await loadRemoteData() }
    }
    .onChange(of: selectedMonth) { _ in
      Task { await loadRemoteData() }
    }
  }

  private var filterBar: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 8) {
        Button {
          viewMode = viewMode == .map ? .list : .map
          selectedMapPinId = nil
        } label: {
          HStack(spacing: 4) {
            Image(systemName: "map")
              .font(.system(size: 13, weight: .bold))
            Text("地图")
              .font(.system(size: 13, weight: .bold))
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 8)
          .background(viewMode == .map ? Color.white : Color.white.opacity(0.52))
          .foregroundColor(viewMode == .map ? Color.black.opacity(0.82) : Color.black.opacity(0.55))
          .clipShape(Capsule())
          .shadow(color: Color.black.opacity(viewMode == .map ? 0.05 : 0), radius: 12, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier("food_memory_toggle_map")

        ForEach(categories, id: \.self) { category in
          Button {
            selectedCategory = category
          } label: {
            Text(category)
              .font(.system(size: 13, weight: .bold))
              .padding(.horizontal, 14)
              .padding(.vertical, 8)
              .background(selectedCategory == category ? Color(hex: "#FF6B6B") : Color.white.opacity(0.52))
              .foregroundColor(selectedCategory == category ? .white : Color.black.opacity(0.55))
              .clipShape(Capsule())
              .shadow(color: Color(hex: "#FF6B6B").opacity(selectedCategory == category ? 0.20 : 0), radius: 12, x: 0, y: 4)
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_category_\(category)")
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 10)
    }
  }

  @ViewBuilder
  private var contentView: some View {
    if viewMode == .list {
      ScrollView(showsIndicators: false) {
        LazyVStack(spacing: 14) {
          ForEach(displayedMemories) { memory in
            FoodMemoryCard(
              memory: memory,
              activeMenuId: $activeMenuId,
              onEdit: { editingMemoryId = memory.id },
              onDelete: { deletingId = memory.id }
            )
            .accessibilityIdentifier("food_memory_card_\(memory.id)")
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 30)
      }
      .accessibilityIdentifier("food_memory_list")
    } else {
      VStack(spacing: 0) {
        mapArea
          .frame(maxWidth: .infinity, maxHeight: .infinity)

        monthSlider
      }
      .accessibilityIdentifier("food_memory_map")
    }
  }

  private var mapArea: some View {
    ZStack {
      Map(coordinateRegion: $mapRegion, annotationItems: displayedMemories) { memory in
        MapAnnotation(coordinate: CLLocationCoordinate2D(latitude: memory.lat, longitude: memory.lng)) {
          Button {
            selectedMapPinId = selectedMapPinId == memory.id ? nil : memory.id
          } label: {
            VStack(spacing: 0) {
              Text(memory.name)
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.white)
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(
                  LinearGradient(
                    colors: selectedMapPinId == memory.id ? [Color(hex: "#EF4444"), Color(hex: "#F97316")] : [Color(hex: "#0EA5E9"), Color(hex: "#22C55E")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                  )
                )
                .clipShape(Capsule())
              Triangle()
                .fill(Color.white.opacity(0.95))
                .frame(width: 10, height: 6)
            }
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_pin_\(memory.id)")
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .padding(.horizontal, 16)
      .padding(.top, 8)

      if let selectedMapPinId,
         let selectedMemory = displayedMemories.first(where: { $0.id == selectedMapPinId }) {
        VStack {
          Spacer()
          FoodMemoryCard(
            memory: selectedMemory,
            activeMenuId: $activeMenuId,
            onEdit: { editingMemoryId = selectedMemory.id },
            onDelete: { deletingId = selectedMemory.id }
          )
          .padding(.horizontal, 16)
          .padding(.bottom, 12)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }

  private var monthSlider: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(months, id: \.self) { month in
          let selected = selectedMonth == month
          let count = monthStats[month] ?? filteredByCategory.filter { $0.lastVisited.hasPrefix(month) }.count
          Button {
            selectedMonth = selected ? nil : month
          } label: {
            VStack(spacing: 6) {
              Text(month)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(selected ? Color.white.opacity(0.6) : Color.black.opacity(0.35))
              Text("\(count)店")
                .font(.system(size: 14, weight: .black))
                .foregroundColor(selected ? .white : Color.black.opacity(0.8))
            }
            .frame(width: 78, height: 74)
            .background(selected ? Color.black.opacity(0.82) : Color.white.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
              RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.black.opacity(selected ? 0 : 0.06), lineWidth: 1)
            )
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_month_\(month.replacingOccurrences(of: "/", with: "_"))")
        }
      }
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
    }
    .background(Color.white.opacity(0.56))
    .overlay(alignment: .top) {
      Rectangle().fill(Color.black.opacity(0.04)).frame(height: 1)
    }
  }

  private func updateMemory(_ edited: FoodMemory) {
    guard let idx = memories.firstIndex(where: { $0.id == edited.id }) else { return }
    Task {
      let remote: RemoteFoodMemoryDTO? = await APIClient().postRequest(
        "/food-memory/update",
        FoodUpdateBody(
          id: edited.id,
          name: edited.name,
          category: edited.cuisine,
          pricePerPerson: edited.pricePerPerson,
          visitedAt: edited.visitedAtMs,
          rating: edited.rating,
          features: edited.features,
          signatureDishes: edited.signatureDishes,
          avoidDishes: edited.avoidDishes,
          review: edited.review,
          photos: edited.photos,
          lat: edited.lat,
          lng: edited.lng,
          address: edited.address
        ),
        true,
        true
      )
      await MainActor.run {
        if let remote {
          memories[idx] = FoodMemory(dto: remote)
        } else {
          memories[idx] = edited
        }
        editingMemoryId = nil
      }
    }
  }

  private func addMockMemory() {
    Task {
      guard let created: RemoteFoodMemoryDTO = await APIClient().postRequest(
        "/food-memory/create",
        FoodCreateBody(
          name: "新美食记忆",
          category: "小吃",
          pricePerPerson: 88,
          visitedAt: Int64(Date().timeIntervalSince1970 * 1000),
          rating: 4,
          features: ["新发现"],
          signatureDishes: ["招牌菜"],
          avoidDishes: [],
          review: "这是新增的模拟数据，可用于 UI 走查。",
          photos: [],
          lat: mapRegion.center.latitude,
          lng: mapRegion.center.longitude,
          address: "当前位置"
        ),
        true,
        true
      ) else { return }
      await MainActor.run {
        memories.insert(FoodMemory(dto: created), at: 0)
      }
      await loadRemoteData()
    }
  }

  @MainActor
  private func loadRemoteData() async {
    if let remote: RemoteFoodMemoryListDTO = await APIClient().postRequest(
      "/food-memory/list",
      FoodListBody(
        category: selectedCategory == "全部" ? "" : selectedCategory,
        month: selectedMonth ?? "",
        page: 1,
        pageSize: 100
      ),
      true,
      false
    ) {
      let remoteItems = remote.items.map(FoodMemory.init(dto:))
      if !remoteItems.isEmpty {
        memories = remoteItems
        updateMapRegion()
      }
    }
    if let monthWrap: RemoteFoodMonthListDTO = await APIClient().getRequest("/food-memory/months", Empty(), true, false) {
      let months = monthWrap.items
      monthStats = Dictionary(uniqueKeysWithValues: months.map { ($0.month, $0.count) })
    }
  }

  private func updateMapRegion() {
    guard !memories.isEmpty else { return }
    let lats = memories.map(\.lat)
    let lngs = memories.map(\.lng)
    guard let minLat = lats.min(), let maxLat = lats.max(), let minLng = lngs.min(), let maxLng = lngs.max() else { return }
    mapRegion = MKCoordinateRegion(
      center: CLLocationCoordinate2D(latitude: (minLat + maxLat) / 2, longitude: (minLng + maxLng) / 2),
      span: MKCoordinateSpan(latitudeDelta: max(0.03, (maxLat - minLat) * 1.8), longitudeDelta: max(0.03, (maxLng - minLng) * 1.8))
    )
  }
}

private extension FoodMemory {
  init(dto: RemoteFoodMemoryDTO) {
    id = dto.id
    name = dto.name
    cuisine = dto.category
    pricePerPerson = dto.pricePerPerson
    rating = dto.rating
    features = dto.features
    signatureDishes = dto.signatureDishes
    avoidDishes = dto.avoidDishes
    review = dto.review
    photos = dto.photos
    lat = dto.lat
    lng = dto.lng
    address = dto.address
    visitedAtMs = dto.visitedAt
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_CN")
    formatter.dateFormat = "yyyy/MM/dd"
    lastVisited = formatter.string(from: Date(timeIntervalSince1970: TimeInterval(dto.visitedAt) / 1000))
  }
}

private struct FoodMemoryCard: View {
  let memory: FoodMemory
  @Binding var activeMenuId: String?
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

          Text("¥\(memory.pricePerPerson)/人 · \(memory.lastVisited)")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(Color.black.opacity(0.35))
        }

        Spacer()

        menuButton
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
            ForEach(memory.photos, id: \.self) { imageName in
              Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 122, height: 94)
                .clipped()
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

  private var menuButton: some View {
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
}

private struct FoodMemoryEditSheet: View {
  let memory: FoodMemory
  let onClose: () -> Void
  let onSave: (FoodMemory) -> Void

  @State private var name: String
  @State private var review: String
  @State private var priceText: String

  init(memory: FoodMemory, onClose: @escaping () -> Void, onSave: @escaping (FoodMemory) -> Void) {
    self.memory = memory
    self.onClose = onClose
    self.onSave = onSave
    _name = State(initialValue: memory.name)
    _review = State(initialValue: memory.review)
    _priceText = State(initialValue: "\(memory.pricePerPerson)")
  }

  var body: some View {
    ZStack {
      Color.black.opacity(0.42).ignoresSafeArea().onTapGesture(perform: onClose)

      VStack(alignment: .leading, spacing: 14) {
        Text("编辑美食记忆")
          .font(.system(size: 20, weight: .black))
        field(title: "店名", text: $name)
        field(title: "人均", text: $priceText)
        Text("点评")
          .font(.system(size: 13, weight: .bold))
          .foregroundColor(Color.black.opacity(0.56))
        TextEditor(text: $review)
          .font(.system(size: 14, weight: .medium))
          .frame(height: 110)
          .padding(8)
          .background(Color(hex: "#F4F5F7"))
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

        HStack(spacing: 10) {
          Button("取消", action: onClose)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#F4F5F7"))
            .foregroundColor(Color.black.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

          Button("保存") {
            var updated = memory
            updated.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
            updated.review = review.trimmingCharacters(in: .whitespacesAndNewlines)
            if let price = Int(priceText) {
              updated.pricePerPerson = price
            }
            onSave(updated)
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 12)
          .background(Color(hex: "#FF6B6B"))
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          .accessibilityIdentifier("food_memory_edit_save")
        }
      }
      .padding(20)
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .padding(.horizontal, 20)
    }
  }

  private func field(title: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(Color.black.opacity(0.56))
      TextField("", text: text)
        .font(.system(size: 14, weight: .medium))
        .padding(.horizontal, 12)
        .frame(height: 44)
        .background(Color(hex: "#F4F5F7"))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
  }
}

private struct FoodDeleteConfirm: View {
  let onCancel: () -> Void
  let onDelete: () -> Void

  var body: some View {
    ZStack {
      Color.black.opacity(0.40).ignoresSafeArea()

      VStack(spacing: 16) {
        Text("确定要删除吗？")
          .font(.system(size: 20, weight: .black))
          .foregroundColor(Color.black.opacity(0.82))

        Text("这条美食记忆将被永久删除，此操作无法恢复。")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color.black.opacity(0.58))

        HStack(spacing: 10) {
          Button("取消", action: onCancel)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#F4F5F7"))
            .foregroundColor(Color.black.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

          Button("删除", action: onDelete)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(Color(hex: "#EF4444"))
            .foregroundColor(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .accessibilityIdentifier("food_memory_confirm_delete")
        }
      }
      .padding(20)
      .background(Color.white)
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .padding(.horizontal, 24)
    }
  }
}

private struct Triangle: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.maxY))
    path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.minX, y: rect.minY))
    path.closeSubpath()
    return path
  }
}
