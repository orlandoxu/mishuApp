import MapKit
import SwiftUI

struct FoodMemoryView: View {
  @ObservedObject private var appNavigation = AppNavigationModel.shared
  @State private var memories: [FoodMemoryItem] = []
  @State private var selectedCategory = "全部"
  @State private var deletingId: String?
  @State private var viewMode: FoodMemoryViewMode = .list
  @State private var selectedMapPinId: String?
  @State private var selectedMonth: String?
  @State private var monthStats: [String: Int] = [:]
  @State private var editingMemory: FoodMemoryItem?
  @State private var pendingEditMemoryId: String?
  @State private var mapRegion = MKCoordinateRegion(
    center: CLLocationCoordinate2D(latitude: 31.2304, longitude: 121.4737),
    span: MKCoordinateSpan(latitudeDelta: 0.12, longitudeDelta: 0.12)
  )

  private let api = FoodMemoryAPI.shared
  private let baseCategories = ["川菜", "日料", "法餐", "小吃", "火锅", "烧烤", "西餐", "其他"]

  private var categories: [String] {
    let memoryCategories = Set(memories.map(\.cuisine))
    let merged = Set(baseCategories).union(memoryCategories)
    return ["全部"] + merged.sorted()
  }

  private var months: [String] {
    monthStats.isEmpty ? ["2026/06", "2026/05", "2026/04", "2026/03", "2026/02", "2026/01"] : monthStats.keys.sorted(by: >)
  }

  private var filteredByCategory: [FoodMemoryItem] {
    selectedCategory == "全部" ? memories : memories.filter { $0.cuisine == selectedCategory }
  }

  private var displayedMemories: [FoodMemoryItem] {
    guard let selectedMonth else { return filteredByCategory }
    return filteredByCategory.filter { $0.lastVisitedText.hasPrefix(selectedMonth) }
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#F8F9FB").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "美食记忆") {
          Button(action: triggerConversationCreate) {
            Image(systemName: "plus")
              .font(.system(size: 21, weight: .bold))
              .foregroundColor(Color(hex: "#FF6B6B"))
          }
          .buttonStyle(.plain)
          .accessibilityIdentifier("food_memory_add_button")
        }

        FoodMemoryFilterBar(
          categories: categories,
          selectedCategory: selectedCategory,
          viewMode: viewMode,
          onToggleMap: {
            viewMode = viewMode == .map ? .list : .map
            selectedMapPinId = nil
          },
          onSelectCategory: { selectedCategory = $0 }
        )

        contentView
      }

      if deletingId != nil {
        FoodDeleteConfirmView(
          onCancel: { deletingId = nil },
          onDelete: { Task { await deleteCurrentMemory() } }
        )
      }

      NavigationLink(
        isActive: Binding(
          get: { editingMemory != nil },
          set: { if !$0 { editingMemory = nil } }
        )
      ) {
        if let memory = editingMemory {
          FoodMemoryEditPageView(memory: memory) { edited in
            Task { await updateMemory(edited) }
          }
        } else {
          Color.clear
        }
      } label: { EmptyView() }
      .hidden()
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
    .onReceive(NotificationCenter.default.publisher(for: .foodMemoryOpenEditor)) { notification in
      guard let id = notification.userInfo?["id"] as? String else { return }
      pendingEditMemoryId = id
      if let matched = memories.first(where: { $0.id == id }) {
        editingMemory = matched
      } else {
        Task { await loadRemoteData() }
      }
    }
  }

  @ViewBuilder
  private var contentView: some View {
    if viewMode == .list {
      ScrollView(showsIndicators: false) {
        Group {
          if displayedMemories.isEmpty {
            FoodMemoryEmptyStateView()
              .frame(minHeight: 520)
          } else {
            LazyVStack(spacing: 14) {
              ForEach(displayedMemories) { memory in
                FoodMemoryCardView(
                  memory: memory,
                  onEdit: { editingMemory = memory },
                  onDelete: { deletingId = memory.id }
                )
                .accessibilityIdentifier("food_memory_card_\(memory.id)")
              }
            }
            .padding(.bottom, 30)
          }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
      }
      .accessibilityIdentifier("food_memory_list")
    } else {
      VStack(spacing: 0) {
        mapArea
          .frame(maxWidth: .infinity, maxHeight: .infinity)

        FoodMemoryMonthSlider(
          months: months,
          selectedMonth: selectedMonth,
          monthStats: monthStats,
          fallbackCountForMonth: { month in filteredByCategory.filter { $0.lastVisitedText.hasPrefix(month) }.count },
          onSelectMonth: { selectedMonth = $0 }
        )
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
         let selectedMemory = displayedMemories.first(where: { $0.id == selectedMapPinId })
      {
        VStack {
          Spacer()
          FoodMemoryCardView(
            memory: selectedMemory,
            onEdit: { editingMemory = selectedMemory },
            onDelete: { deletingId = selectedMemory.id }
          )
          .padding(.horizontal, 16)
          .padding(.bottom, 12)
        }
        .transition(.move(edge: .bottom).combined(with: .opacity))
      }
    }
  }

  private func triggerConversationCreate() {
    appNavigation.popToRoot()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
      NotificationCenter.default.post(
        name: .homeQuickTextInput,
        object: nil,
        userInfo: ["text": "帮我新增一条美食记忆"]
      )
    }
  }

  @MainActor
  private func loadRemoteData() async {
    if let remote = await api.list(
      category: selectedCategory == "全部" ? nil : selectedCategory,
      month: selectedMonth,
      page: 1,
      pageSize: 100
    ) {
      memories = remote.items.map(FoodMemoryItem.init(dto:))
      updateMapRegion()
      if let pendingEditMemoryId,
         let matched = memories.first(where: { $0.id == pendingEditMemoryId })
      {
        editingMemory = matched
        self.pendingEditMemoryId = nil
      }
    }

    if let remoteMonths = await api.months() {
      monthStats = Dictionary(uniqueKeysWithValues: remoteMonths.map { ($0.month, $0.count) })
    }
  }

  @MainActor
  private func updateMemory(_ edited: FoodMemoryItem) async {
    guard let idx = memories.firstIndex(where: { $0.id == edited.id }) else { return }

    if let remote = await api.update(payload: .init(item: edited)) {
      memories[idx] = FoodMemoryItem(dto: remote)
    } else {
      memories[idx] = edited
      ToastCenter.shared.show("保存失败，请稍后重试")
    }
  }

  @MainActor
  private func deleteCurrentMemory() async {
    guard let deletingId else { return }
    let success = await api.delete(id: deletingId)
    if success {
      memories.removeAll { $0.id == deletingId }
      selectedMapPinId = selectedMapPinId == deletingId ? nil : selectedMapPinId
    } else {
      ToastCenter.shared.show("删除失败，请稍后重试")
    }
    self.deletingId = nil
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
