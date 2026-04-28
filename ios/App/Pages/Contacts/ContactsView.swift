import SwiftUI

struct ContactsView: View {
  @State private var activeId = "li"
  @State private var showAll = false
  @State private var searchQuery = ""

  private let contacts: [PrototypeContact] = [
    PrototypeContact(
      id: "sarah",
      name: "林莎",
      shortName: "林莎",
      role: "亚太区设计副总裁 @奥格威",
      avatarText: "莎",
      isStarred: true,
      colors: [Color(hex: "#8C7CF0"), Color(hex: "#614CE5")],
      tags: ["超高净值网络", "校友"],
      preferences: ["极简美学控", "重度手冲咖啡爱好者", "偏爱 Le Labo 香氛", "沟通讲究极致高效"],
      resources: ["顶级的品牌视觉重塑能力", "T1级别媒体与公关人脉圈", "极具敏锐的商业跨界洞察"],
      insight: "下周五是她的生日，或许是个增进连接的绝佳契机。",
      interactions: ["上月协助 Alpha 创新项目排期", "危机公关事件中提供驻场协助"]
    ),
    PrototypeContact(
      id: "alex",
      name: "陈天宇",
      shortName: "天宇",
      role: "创始合伙人 @曜石资本",
      avatarText: "宇",
      isStarred: true,
      colors: [Color(hex: "#FBBF24"), Color(hex: "#F97316")],
      tags: ["一级市场", "高尔夫球友"],
      preferences: ["关注通用人工智能", "注重晨练", "重度红酒爱好者"],
      resources: ["百亿级出海基金背书", "深厚硅谷人脉圈", "二级市场退出理解"],
      insight: "本周六打球或许适合私下交流海外并购重组。",
      interactions: ["周末观澜湖高尔夫", "通过林莎建立联系"]
    ),
    PrototypeContact(
      id: "li",
      name: "李昂",
      shortName: "李昂",
      role: "主理人 @极致运动科学",
      avatarText: "昂",
      isStarred: true,
      colors: [Color(hex: "#34D399"), Color(hex: "#14B8A6")],
      tags: ["健康私董", "户外搭子"],
      preferences: ["严格生酮饮食", "热爱硬核越野", "偏好功能性科技装备"],
      resources: ["顶尖运动康复医疗资源", "本地户外企业家圈层", "赛事后勤保障团队"],
      insight: "你的体脂管理数据停滞两周，可以借体验新恢复舱自然恢复沟通。",
      interactions: ["百公里越野体能储备", "恢复训练方案复盘"]
    ),
    PrototypeContact(
      id: "wang",
      name: "王小伟",
      shortName: "小伟",
      role: "高级研发工程师 @某科技大厂",
      avatarText: "伟",
      isStarred: false,
      colors: [Color(hex: "#94A3B8"), Color(hex: "#64748B")],
      tags: ["前同事", "技术控"],
      preferences: ["关注开源圈子", "技术分享狂热者"],
      resources: ["精通微服务架构", "极强排错能力"],
      insight: "他想尝试独立开发 AI 小工具，可以探讨技术合作。",
      interactions: ["高并发数据流处理架构讨论"]
    ),
    PrototypeContact(
      id: "zhang",
      name: "张浩然",
      shortName: "浩然",
      role: "自由摄影师 / 策展人",
      avatarText: "然",
      isStarred: false,
      colors: [Color(hex: "#A8A29E"), Color(hex: "#78716C")],
      tags: ["艺术圈", "旅行者"],
      preferences: ["独立电影", "胶片摄影", "不喜强社交"],
      resources: ["国内外独立画廊人脉", "极佳的审美把控力"],
      insight: "他最近在筹备一个关于城市废墟的影展，正好你的新品牌视觉可能需要这类先锋元素。",
      interactions: ["去他的工作室喝下午茶，聊了聊影像语言重塑。"]
    )
  ]

  private var activeContact: PrototypeContact {
    contacts.first { $0.id == activeId } ?? contacts[0]
  }

  private var filteredContacts: [PrototypeContact] {
    let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else { return contacts }
    return contacts.filter { contact in
      contact.name.localizedCaseInsensitiveContains(query) ||
      contact.role.localizedCaseInsensitiveContains(query) ||
      contact.tags.contains { $0.localizedCaseInsensitiveContains(query) } ||
      contact.resources.contains { $0.localizedCaseInsensitiveContains(query) }
    }
  }

  private var starredContacts: [PrototypeContact] {
    filteredContacts.filter(\.isStarred)
  }

  private var otherContacts: [PrototypeContact] {
    filteredContacts.filter { !$0.isStarred }
  }

  var body: some View {
    ZStack(alignment: .top) {
      LinearGradient(
        colors: [activeContact.colors.first?.opacity(0.18) ?? .clear, Color(hex: "#F6F7FB")],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()

      if showAll {
        allContactsList
      } else {
        contactDetail
      }

      NavHeader(title: showAll ? "全部联系人" : "")
    }
  }

  private var contactDetail: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 0) {
        ZStack(alignment: .trailing) {
          ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
              HStack(spacing: 8) {
                ForEach(contacts) { contact in
                  ContactAvatarButton(contact: contact, isActive: contact.id == activeId) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.85)) {
                      activeId = contact.id
                      proxy.scrollTo(contact.id, anchor: .center)
                    }
                  }
                  .id(contact.id)
                }
              }
              .padding(.leading, UIScreen.main.bounds.width / 2 - 32)
              .padding(.trailing, 120)
              .padding(.vertical, 16)
            }
            .onAppear {
              DispatchQueue.main.async {
                proxy.scrollTo(activeId, anchor: .center)
              }
            }
          }

          LinearGradient(
            colors: [Color(hex: "#F6F7FB").opacity(0), Color(hex: "#F6F7FB").opacity(0.70), Color(hex: "#F6F7FB")],
            startPoint: .leading,
            endPoint: .trailing
          )
          .frame(width: 124)
          .allowsHitTesting(false)

          VStack(spacing: 8) {
            Button {
              showAll = true
            } label: {
              ZStack {
                Circle()
                  .fill(Color.white.opacity(0.40))
                  .frame(width: 64, height: 64)
                  .overlay(Circle().stroke(Color.black.opacity(0.05), lineWidth: 1))
                  .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
                Image(systemName: "person.3.fill")
                  .font(.system(size: 20, weight: .medium))
                  .foregroundColor(Color.black.opacity(0.40))
              }
              .scaleEffect(0.62)
            }
            .buttonStyle(.plain)
            Text("全部")
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(Color.black.opacity(0.30))
          }
          .frame(width: 74)
          .padding(.trailing, 12)
        }

        ContactProfileSummary(contact: activeContact)
          .padding(.horizontal, 20)
          .padding(.top, 24)
          .padding(.bottom, 24)

        ContactDetailCard(contact: activeContact)
          .padding(.horizontal, 20)
          .padding(.top, 0)
      }
      .padding(.top, 96)
      .padding(.bottom, 32)
    }
  }

  private var allContactsList: some View {
    ScrollView(showsIndicators: false) {
      VStack(alignment: .leading, spacing: 0) {
        HStack(spacing: 12) {
          Image(systemName: "magnifyingglass")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(Color.black.opacity(0.30))
          TextField("搜索联系人、标签或资源...", text: $searchQuery)
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color.black.opacity(0.80))
        }
        .frame(height: 48)
        .padding(.horizontal, 16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(Color.black.opacity(0.05), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 8, x: 0, y: 2)
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 18)

        if !starredContacts.isEmpty {
          ContactListSection(title: "星标核心 (Starred)", contacts: starredContacts, onSelect: selectContact)
            .padding(.top, 4)
        }

        if !otherContacts.isEmpty {
          ContactListSection(title: "所有联系人 (All)", contacts: otherContacts, onSelect: selectContact)
            .padding(.top, 28)
        }

        if filteredContacts.isEmpty {
          VStack(spacing: 12) {
            Image(systemName: "magnifyingglass")
              .font(.system(size: 42, weight: .light))
              .foregroundColor(Color.black.opacity(0.08))
            Text("未找到相关联系人")
              .font(.system(size: 15, weight: .medium))
              .foregroundColor(Color.black.opacity(0.20))
          }
          .frame(maxWidth: .infinity)
          .padding(.top, 80)
        }
      }
      .padding(.top, safeAreaTop + 76)
      .padding(.bottom, 40)
    }
  }

  private func selectContact(_ contact: PrototypeContact) {
    activeId = contact.id
    searchQuery = ""
    showAll = false
  }
}

private struct ContactListSection: View {
  let title: String
  let contacts: [PrototypeContact]
  let onSelect: (PrototypeContact) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(title)
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(Color.black.opacity(0.30))
        .tracking(1.8)
        .textCase(.uppercase)
        .padding(.horizontal, 20)

      VStack(spacing: 0) {
        ForEach(Array(contacts.enumerated()), id: \.element.id) { index, contact in
          Button {
            onSelect(contact)
          } label: {
            HStack(spacing: 16) {
              ZStack(alignment: .bottomTrailing) {
                Circle()
                  .fill(LinearGradient(colors: contact.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
                  .frame(width: 46, height: 46)
                  .overlay(Circle().stroke(Color.white, lineWidth: 2))
                Text(contact.avatarText)
                  .font(.system(size: 14, weight: .bold))
                  .foregroundColor(.white)
                if contact.isStarred {
                  Image(systemName: "star.fill")
                    .font(.system(size: 9, weight: .black))
                    .foregroundColor(Color(hex: "#FBBF24"))
                    .offset(x: 2, y: 2)
                }
              }

              VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                  Text(contact.name)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color.black.opacity(0.90))
                  if contact.isStarred {
                    Image(systemName: "star.fill")
                      .font(.system(size: 13, weight: .black))
                      .foregroundColor(Color(hex: "#FBBF24"))
                  }
                }
                Text(contact.role.components(separatedBy: " @").first ?? contact.role)
                  .font(.system(size: 13, weight: .medium))
                  .foregroundColor(Color.black.opacity(0.40))
                  .lineLimit(1)
              }

              Spacer()

              Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(Color.black.opacity(0.20))
            }
            .padding(16)
            .background(Color.white)
          }
          .buttonStyle(.plain)

          if index != contacts.count - 1 {
            Rectangle()
              .fill(Color.black.opacity(0.03))
              .frame(height: 1)
              .padding(.leading, 78)
          }
        }
      }
      .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 24, style: .continuous)
          .stroke(Color.black.opacity(0.03), lineWidth: 1)
      )
      .shadow(color: Color.black.opacity(0.02), radius: 20, x: 0, y: 4)
      .padding(.horizontal, 20)
    }
  }
}
