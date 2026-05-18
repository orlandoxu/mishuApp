import SwiftUI

struct ContactsView: View {
  struct RemoteInteractionDTO: Codable {
    let id: String
    let date: String
    let type: String
    let desc: String
  }

  struct RemoteFriendDTO: Codable {
    let id: String
    let name: String
    let shortName: String
    let age: Int
    let gender: String
    let role: String
    let avatarText: String
    let isStarred: Bool
    let starredAt: String?
    let tags: [String]
    let birthday: String?
    let relationship: String?
    let preferences: [String]
    let resources: [String]
    let insight: String
    let interactions: [RemoteInteractionDTO]
  }

  struct RemoteFriendListDTO: Codable {
    let items: [RemoteFriendDTO]
    let total: Int
    let page: Int
    let pageSize: Int
  }

  struct FriendListBody: Encodable {
    let page: Int
    let pageSize: Int
  }

  struct FriendDeleteBody: Encodable {
    let friendId: String
  }

  struct FriendInteractionDeleteBody: Encodable {
    let interactionId: String
  }

  private enum Style {
    static let horizontalPadding: CGFloat = 20
    static let nameFont: CGFloat = 25
    static let ageFont: CGFloat = 13.5
    static let infoFont: CGFloat = 17.5
    static let infoIconFont: CGFloat = 15
    static let interactionTitleFont: CGFloat = 18
  }

  @State private var contactsData: [PrototypeContact] = ContactsMockData.all
  @State private var activeId: String = "li"
  @State private var showList = false
  @State private var showDeleteConfirm = false

  private var activeContact: PrototypeContact {
    contactsData.first(where: { $0.id == activeId }) ?? contactsData[0]
  }

  private var topContacts: [PrototypeContact] {
    contactsData.sorted { lhs, rhs in
      if lhs.isStarred != rhs.isStarred {
        return lhs.isStarred
      }
      if let left = lhs.starredAt, let right = rhs.starredAt {
        return left < right
      }
      return lhs.id < rhs.id
    }
  }

  init() {
    let starred = ContactsMockData.all.filter { $0.isStarred && $0.starredAt != nil }
    if let latest = starred.max(by: { ($0.starredAt ?? "") < ($1.starredAt ?? "") }) {
      _activeId = State(initialValue: latest.id)
    }
  }

  var body: some View {
    Group {
      if showList {
        ContactsListScreen(
          contacts: contactsData,
          onClose: { showList = false },
          onSelect: { contact in
            activeId = contact.id
            showList = false
          }
        )
      } else {
        content
      }
    }
    .task {
      await loadContactsFromRemote()
    }
  }

  private var content: some View {
    ZStack {
      LinearGradient(
        colors: [activeContact.colors.first?.opacity(0.14) ?? .clear, Color(hex: "#F6F7FB")],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        header
        ScrollView(showsIndicators: false) {
          VStack(alignment: .leading, spacing: 0) {
            profileSection
            interactionSection
              .padding(.top, 32)
            Spacer(minLength: 220)
          }
          .padding(.horizontal, Style.horizontalPadding)
        }
      }

      bottomActions

      if showDeleteConfirm {
        deleteConfirmOverlay
      }
    }
  }

  private var header: some View {
    HStack(spacing: 12) {
      Button { AppNavigationModel.shared.pop() } label: {
        Image(systemName: "arrow.left")
          .font(.system(size: 20, weight: .semibold))
          .foregroundColor(Color.black.opacity(0.72))
          .frame(width: 42, height: 42)
          .background(Color.white.opacity(0.80))
          .clipShape(Circle())
      }
      .buttonStyle(.plain)

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 6) {
          ForEach(topContacts) { contact in
            ContactTopAvatarItem(contact: contact, isActive: contact.id == activeId) {
              withAnimation(.spring(response: 0.32, dampingFraction: 0.84)) {
                activeId = contact.id
              }
            }
          }
        }
      }

      Button {
        showList = true
      } label: {
        Image(systemName: "person.3.fill")
          .font(.system(size: 15, weight: .medium))
          .foregroundColor(Color.black.opacity(0.42))
          .frame(width: 44, height: 44)
          .background(Color.white.opacity(0.62))
          .clipShape(Circle())
          .overlay(Circle().stroke(Color.black.opacity(0.06), lineWidth: 1))
      }
      .buttonStyle(.plain)
      .accessibilityIdentifier("contacts_show_all_button")
    }
    .padding(.horizontal, 14)
    .padding(.top, 26)
    .padding(.bottom, 10)
  }

  private var profileSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 10) {
        Text(activeContact.name)
          .font(.system(size: Style.nameFont, weight: .bold))
          .foregroundColor(Color.black.opacity(0.90))
        Text("\(activeContact.age)岁")
          .font(.system(size: Style.ageFont, weight: .medium))
          .foregroundColor(Color.black.opacity(0.52))
          .padding(.horizontal, 8)
          .padding(.vertical, 3)
          .background(Color.black.opacity(0.05))
          .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
        genderIcon
      }
      .padding(.top, 16)

      infoRow(symbol: "person", text: activeContact.birthday.map { "\($0) · \(activeContact.relationship ?? "")" } ?? "未记录TA的基础信息")
      infoRow(symbol: "bolt", text: activeContact.resources.isEmpty ? "未记录TA的能量图谱" : activeContact.resources.joined(separator: " · "))
      infoRow(symbol: "gift", text: activeContact.preferences.isEmpty ? "未记录TA的个人爱好" : activeContact.preferences.joined(separator: " · "))
    }
  }

  @ViewBuilder
  private var genderIcon: some View {
    if activeContact.gender == "男" {
      Text("♂")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(Color(hex: "#2563EB"))
        .accessibilityIdentifier("contacts_gender_icon")
    } else if activeContact.gender == "女" {
      Text("♀")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(Color(hex: "#DB2777"))
        .accessibilityIdentifier("contacts_gender_icon")
    } else {
      Text(activeContact.gender)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(Color.black.opacity(0.50))
        .accessibilityIdentifier("contacts_gender_icon")
    }
  }

  private func infoRow(symbol: String, text: String) -> some View {
    HStack(alignment: .top, spacing: 8) {
      Image(systemName: symbol)
        .font(.system(size: Style.infoIconFont, weight: .regular))
        .foregroundColor(Color.black.opacity(0.46))
        .frame(width: 17, height: 17)
        .padding(.top, 2)
      Text(text)
        .font(.system(size: Style.infoFont, weight: .semibold))
        .foregroundColor(Color.black.opacity(0.78))
        .lineSpacing(5)
    }
  }

  private var interactionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("和TA互动")
          .font(.system(size: Style.interactionTitleFont, weight: .bold))
          .foregroundColor(Color.black.opacity(0.90))
          .layoutPriority(1)
        Spacer()
        ContactsRotatingQuoteView()
          .accessibilityIdentifier("contacts_rotating_quote")
      }

      if activeContact.interactions.isEmpty {
        VStack(spacing: 8) {
          Image(systemName: "arrow.left.arrow.right")
            .font(.system(size: 20, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.20))
          Text("还没有互动记录")
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(Color.black.opacity(0.40))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
      } else {
        VStack(spacing: 14) {
          ForEach(Array(activeContact.interactions.enumerated()), id: \.offset) { idx, interaction in
            ContactTimelineCard(
              interaction: interaction,
              onCopy: {
                UIPasteboard.general.string = interaction.desc
                ToastCenter.shared.show("复制成功")
              },
              onDelete: {
                deleteInteraction(contactId: activeContact.id, index: idx)
              }
            )
          }
        }
      }
    }
  }

  private var bottomActions: some View {
    VStack {
      Spacer()
      HStack(spacing: 14) {
        bottomActionButton(systemImage: "bubble.left", tint: Color.black.opacity(0.50)) {
          ToastCenter.shared.show("聊天入口待接入")
        }
        bottomActionButton(systemImage: "pencil", tint: Color(hex: "#6B7280")) {
          ToastCenter.shared.show("编辑入口待接入")
        }
        bottomActionButton(systemImage: "trash", tint: Color(hex: "#EF4444").opacity(0.88)) {
          showDeleteConfirm = true
        }
      }
      .padding(.bottom, 34)
    }
  }

  private func bottomActionButton(systemImage: String, tint: Color, action: @escaping () -> Void) -> some View {
    Button(action: action) {
      Image(systemName: systemImage)
        .font(.system(size: 21, weight: .regular))
        .foregroundColor(tint)
        .frame(width: 54, height: 54)
        .background(Color.white)
        .clipShape(Circle())
        .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 0.8))
        .shadow(color: Color.black.opacity(0.035), radius: 8, x: 0, y: 2)
    }
    .buttonStyle(.plain)
  }

  private var deleteConfirmOverlay: some View {
    ZStack {
      Color.black.opacity(0.22)
        .ignoresSafeArea()
        .onTapGesture { showDeleteConfirm = false }

      VStack(spacing: 12) {
        Text("删除联系人")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(Color.black.opacity(0.92))
        Text("确定要删除 \(activeContact.name) 吗？此操作无法撤销。")
          .font(.system(size: 14, weight: .medium))
          .foregroundColor(Color.black.opacity(0.55))
          .multilineTextAlignment(.center)
        HStack(spacing: 10) {
          Button("取消") { showDeleteConfirm = false }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 11)
            .background(Color.black.opacity(0.05))
            .foregroundColor(Color.black.opacity(0.62))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
          Button("确认删除") {
            deleteActiveContact()
            showDeleteConfirm = false
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 11)
          .background(Color(hex: "#EF4444"))
          .foregroundColor(.white)
          .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
      }
      .padding(20)
      .frame(maxWidth: 320)
      .background(.white)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .padding(.horizontal, 20)
    }
  }

  private func deleteInteraction(contactId: String, index: Int) {
    guard let contactIdx = contactsData.firstIndex(where: { $0.id == contactId }) else { return }
    var updated = contactsData[contactIdx]
    guard updated.interactions.indices.contains(index) else { return }
    let interactionId = updated.interactions[index].id
    if let interactionId {
      Task {
        let deleted: Empty? = await APIClient().postRequest(
          "/friend/interactions/delete",
          FriendInteractionDeleteBody(interactionId: interactionId),
          true,
          true
        )
        let success = deleted != nil
        if !success {
          await MainActor.run {
            ToastCenter.shared.show("删除失败，请稍后重试")
          }
        }
      }
    }
    updated = PrototypeContact(
      id: updated.id,
      name: updated.name,
      shortName: updated.shortName,
      age: updated.age,
      gender: updated.gender,
      role: updated.role,
      avatarText: updated.avatarText,
      isStarred: updated.isStarred,
      starredAt: updated.starredAt,
      colors: updated.colors,
      tags: updated.tags,
      birthday: updated.birthday,
      relationship: updated.relationship,
      preferences: updated.preferences,
      resources: updated.resources,
      insight: updated.insight,
      interactions: updated.interactions.enumerated().filter { $0.offset != index }.map { $0.element }
    )
    contactsData[contactIdx] = updated
  }

  private func deleteActiveContact() {
    let removedId = activeId
    Task {
      let deleted: Empty? = await APIClient().postRequest(
        "/friend/delete",
        FriendDeleteBody(friendId: removedId),
        true,
        true
      )
      let success = deleted != nil
      if !success {
        await MainActor.run { ToastCenter.shared.show("删除失败，请稍后重试") }
      }
    }
    contactsData.removeAll { $0.id == removedId }
    if let next = contactsData.first {
      activeId = next.id
    } else {
      AppNavigationModel.shared.pop()
    }
  }

  @MainActor
  private func loadContactsFromRemote() async {
    guard let remote: RemoteFriendListDTO = await APIClient().postRequest(
      "/friend/list",
      FriendListBody(page: 1, pageSize: 100),
      true,
      false
    ) else { return }
    let mapped = remote.items.map { $0.toPrototypeContact() }
    guard !mapped.isEmpty else { return }
    contactsData = mapped
    if !contactsData.contains(where: { $0.id == activeId }) {
      activeId = contactsData.first?.id ?? activeId
    }
  }
}

private struct ContactsRotatingQuoteView: View {
  private let quotes = [
    "人情紧过债", "礼轻情意重", "关系靠来往", "贵在惦记",
    "好关系，靠记得", "最好的礼物，是惦记", "常常想起你",
    "心意不大，但别丢了", "把在乎，变成记得", "不是算账，是记情",
    "别让好友成老友", "人情靠来往", "记事，也是记人",
    "小来往，大关系", "说到做到", "回礼是艺术",
    "关系需要保鲜", "情分靠珍惜"
  ]

  @State private var index = 0
  private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

  var body: some View {
    ZStack {
      Text(quotes[index])
        .id(index)
        .font(.system(size: 13, weight: .medium))
        .foregroundColor(Color.black.opacity(0.30))
        .lineLimit(1)
        .transition(.asymmetric(insertion: .move(edge: .bottom).combined(with: .opacity), removal: .move(edge: .top).combined(with: .opacity)))
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .frame(height: 24)
    .clipped()
    .animation(.easeInOut(duration: 0.8), value: index)
    .onReceive(timer) { _ in
      guard quotes.count > 1 else { return }
      index = Int.random(in: 0..<quotes.count)
    }
  }
}

private struct ContactsListScreen: View {
  let contacts: [PrototypeContact]
  let onClose: () -> Void
  let onSelect: (PrototypeContact) -> Void

  @State private var searchQuery = ""
  @State private var showStarredOnly = false

  private var filteredContacts: [PrototypeContact] {
    contacts.filter { contact in
      let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
      let matchesQuery = query.isEmpty ||
        contact.name.localizedCaseInsensitiveContains(query) ||
        contact.role.localizedCaseInsensitiveContains(query) ||
        contact.tags.contains(where: { $0.localizedCaseInsensitiveContains(query) }) ||
        contact.resources.contains(where: { $0.localizedCaseInsensitiveContains(query) })
      let matchesStarred = !showStarredOnly || contact.isStarred
      return matchesQuery && matchesStarred
    }
  }

  var body: some View {
    ZStack(alignment: .top) {
      Color(hex: "#FAFAFC").ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "全部联系人", onBack: onClose) {
          Image(systemName: "plus")
            .font(.system(size: 20, weight: .bold))
            .foregroundColor(Color.black.opacity(0.58))
        }

        HStack(spacing: 8) {
          Button {
            showStarredOnly.toggle()
          } label: {
            Image(systemName: showStarredOnly ? "star.fill" : "star")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(showStarredOnly ? Color(hex: "#F59E0B") : Color.black.opacity(0.30))
              .frame(width: 48, height: 48)
              .background(showStarredOnly ? Color(hex: "#FEF3C7").opacity(0.70) : .white)
              .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                  .stroke(Color.black.opacity(0.06), lineWidth: 1)
              )
          }
          .buttonStyle(.plain)

          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 14, weight: .semibold))
              .foregroundColor(Color.black.opacity(0.30))
            TextField("搜索联系人、标签或资源...", text: $searchQuery)
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(Color.black.opacity(0.84))
              .accessibilityIdentifier("contacts_search_field")
          }
          .padding(.horizontal, 14)
          .frame(height: 48)
          .background(Color.white)
          .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
          .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
              .stroke(Color.black.opacity(0.05), lineWidth: 1)
          )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 12)

        ScrollView(showsIndicators: false) {
          if filteredContacts.isEmpty {
            VStack(spacing: 10) {
              Image(systemName: "magnifyingglass")
                .font(.system(size: 40, weight: .light))
                .foregroundColor(Color.black.opacity(0.14))
              Text("未找到相关联系人")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(Color.black.opacity(0.34))
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 90)
          } else {
            VStack(spacing: 0) {
              ForEach(Array(filteredContacts.enumerated()), id: \.element.id) { idx, contact in
                ContactListRow(contact: contact, action: { onSelect(contact) }, isLast: idx == filteredContacts.count - 1)
                  .accessibilityIdentifier("contact_list_item_\(contact.id)")
              }
            }
          }
        }
      }
    }
    .accessibilityIdentifier("contacts_all_list_page")
  }
}

private enum ContactsMockData {
  static let all: [PrototypeContact] = [
    PrototypeContact(id: "sarah", name: "林莎", shortName: "林莎", age: 32, gender: "女", role: "亚太区设计副总裁 @奥格威", avatarText: "莎", isStarred: true, starredAt: "2026-04-01T10:00:00Z", colors: [Color(hex: "#8C7CF0"), Color(hex: "#614CE5")], tags: ["超高净值网络", "校友"], birthday: "1994/05/10", relationship: "合作伙伴", preferences: ["极简美学控", "重度手冲咖啡爱好者", "偏爱 Le Labo 香氛", "沟通讲究极致高效"], resources: ["顶级的品牌视觉重塑能力", "T1级别媒体与公关人脉圈", "极具敏锐的商业跨界洞察"], insight: "上月您协助了她的 Alpha 创新项目排期。下周五是她的生日，或许是个增进连接的绝佳契机。", interactions: [.init(date: "2026.03.15", type: "帮忙", desc: "在危机公关事件中，我方调动核心技术团队提供了 48 小时的驻场协助排查。"), .init(date: "2026.02.10", type: "礼物赠送", desc: "寄送了她偏好的 Le Labo 香氛作为其新项目启动的贺礼。"), .init(date: "2026.01.10", type: "帮忙", desc: "在一个非常私密的创始人晚宴上，她主动将我引荐给了正在寻觅领投方的关键投资合伙人 Alex。")]),
    PrototypeContact(id: "alex", name: "陈天宇", shortName: "天宇", age: 35, gender: "男", role: "创始合伙人 @曜石资本", avatarText: "宇", isStarred: true, starredAt: "2026-04-10T10:00:00Z", colors: [Color(hex: "#FBBF24"), Color(hex: "#F97316")], tags: ["一级市场", "高尔夫球友"], birthday: "1991/08/20", relationship: "球友", preferences: [], resources: ["百亿级出海基金直接背书", "深厚的硅谷本土人脉圈", "深刻的二级市场退出理解"], insight: "昨晚他在朋友圈提及合伙人刚刚入华，本周六打球或许是个私下交流海外并购重组的极好时机。", interactions: [.init(date: "2026.04.12", type: "聚会", desc: "周末一起去观澜湖打了一场高尔夫，聊了聊关于今年 AI 出海大盘的共识。"), .init(date: "2026.03.20", type: "约定", desc: "约定下月初对几个出海并购目标项目进行深度尽调。"), .init(date: "2026.01.10", type: "记忆", desc: "通过 林莎 在奥格威内部跨界晚宴上正式建立联系。")]),
    PrototypeContact(id: "li", name: "李昂", shortName: "李昂", age: 28, gender: "男", role: "主理人 @极致运动科学", avatarText: "昂", isStarred: true, starredAt: "2026-04-20T10:00:00Z", colors: [Color(hex: "#34D399"), Color(hex: "#14B8A6")], tags: ["健康私董", "户外搭子"], birthday: "1998/02/15", relationship: "运动教练", preferences: ["严格生酮饮食", "热爱硬核越野", "偏好功能性科技装备"], resources: ["最顶尖的运动康复医疗资源", "本地高质量户外企业家圈层", "顶级赛事后勤保障团队"], insight: "您的核心体脂管理数据已经停滞两周。昨天他刚好引进了一批高频物理恢复舱，可以借体验新设备顺理成章地恢复沟通。", interactions: [.init(date: "2026.04.30", type: "重要事情", desc: "获悉其最近正在处理一项重要的家族资产重组事宜。"), .init(date: "2026.02.28", type: "帮忙", desc: "在他的体系化高压指导下，成功完成了百公里越野的终极体能储备，体能超预期。")]),
    PrototypeContact(id: "wang", name: "王小伟", shortName: "小伟", age: 27, gender: "男", role: "高级研发工程师 @某科技大厂", avatarText: "伟", isStarred: false, starredAt: nil, colors: [Color(hex: "#94A3B8"), Color(hex: "#64748B")], tags: ["前同事", "技术控"], birthday: nil, relationship: nil, preferences: ["关注开源圈子", "技术分享狂热者", "工作狂"], resources: [], insight: "上周他提到了想要尝试独立开发一些 AI 小工具，或许可以探讨一下技术合作的可能性。", interactions: [.init(date: "2026.05.01", type: "问候", desc: "发消息询问了其近期工作状态，提醒注意身体。"), .init(date: "2025.11.05", type: "记忆", desc: "向他请教了关于高并发数据流处理的架构设计问题。")]),
    PrototypeContact(id: "zhang", name: "张浩然", shortName: "浩然", age: 30, gender: "男", role: "自由摄影师 / 策展人", avatarText: "然", isStarred: false, starredAt: nil, colors: [Color(hex: "#A8A29E"), Color(hex: "#78716C")], tags: ["艺术圈", "旅行者"], birthday: "1996/11/12", relationship: "朋友", preferences: [], resources: [], insight: "他最近在筹备一个关于\"城市废墟\"的影展，正好您的新品牌视觉可能需要这类先锋元素。", interactions: [.init(date: "2026.05.10", type: "钱款往来", desc: "返还了上次聚会垫付的餐费。"), .init(date: "2026.02.14", type: "聚会", desc: "去他的工作室喝了一次下午茶，聊了聊关于影像语言重塑的观点。")])
  ]
}

private extension ContactsView.RemoteFriendDTO {
  func toPrototypeContact() -> PrototypeContact {
    let fallbackColorMap: [String: [Color]] = [
      "sarah": [Color(hex: "#8C7CF0"), Color(hex: "#614CE5")],
      "alex": [Color(hex: "#FBBF24"), Color(hex: "#F97316")],
      "li": [Color(hex: "#34D399"), Color(hex: "#14B8A6")],
      "wang": [Color(hex: "#94A3B8"), Color(hex: "#64748B")],
      "zhang": [Color(hex: "#A8A29E"), Color(hex: "#78716C")],
    ]

    return PrototypeContact(
      id: id,
      name: name,
      shortName: shortName,
      age: age,
      gender: gender,
      role: role,
      avatarText: avatarText,
      isStarred: isStarred,
      starredAt: starredAt,
      colors: fallbackColorMap[id] ?? [Color(hex: "#9CA3AF"), Color(hex: "#6B7280")],
      tags: tags,
      birthday: birthday,
      relationship: relationship,
      preferences: preferences,
      resources: resources,
      insight: insight,
      interactions: interactions.map { .init(id: $0.id, date: $0.date, type: $0.type, desc: $0.desc) }
    )
  }
}
