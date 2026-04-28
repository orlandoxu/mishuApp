import SwiftUI

struct ContactsView: View {
  @State private var activeId = "li"
  @State private var showAll = false

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
    )
  ]

  private var activeContact: PrototypeContact {
    contacts.first { $0.id == activeId } ?? contacts[0]
  }

  var body: some View {
    ZStack(alignment: .top) {
      LinearGradient(
        colors: [activeContact.colors.first?.opacity(0.18) ?? .clear, Color(hex: "#F6F7FB")],
        startPoint: .top,
        endPoint: .center
      )
      .ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: showAll ? "全部联系人" : "")

        if showAll {
          allContactsList
        } else {
          contactDetail
        }
      }
    }
  }

  private var contactDetail: some View {
    ScrollView(showsIndicators: false) {
      VStack(spacing: 22) {
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 8) {
            ForEach(contacts) { contact in
              ContactAvatarButton(contact: contact, isActive: contact.id == activeId) {
                activeId = contact.id
              }
            }
            Button {
              showAll = true
            } label: {
              VStack(spacing: 8) {
                Circle()
                  .fill(Color.white.opacity(0.60))
                  .frame(width: 44, height: 44)
                  .overlay(Image(systemName: "person.3.fill").foregroundColor(Color.black.opacity(0.35)))
                Text("全部")
                  .font(.system(size: 12, weight: .medium))
                  .foregroundColor(Color.black.opacity(0.35))
              }
              .frame(width: 74)
            }
            .buttonStyle(.plain)
          }
          .padding(.horizontal, 20)
          .padding(.vertical, 12)
        }

        ContactDetailCard(contact: activeContact)
          .padding(.horizontal, 20)
      }
      .padding(.bottom, 32)
    }
  }

  private var allContactsList: some View {
    List {
      ForEach(contacts) { contact in
        Button {
          activeId = contact.id
          showAll = false
        } label: {
          HStack(spacing: 14) {
            Circle()
              .fill(LinearGradient(colors: contact.colors, startPoint: .topLeading, endPoint: .bottomTrailing))
              .frame(width: 48, height: 48)
              .overlay(Text(contact.avatarText).font(.system(size: 16, weight: .bold)).foregroundColor(.white))
            VStack(alignment: .leading, spacing: 4) {
              Text(contact.name).font(.system(size: 16, weight: .bold)).foregroundColor(.black.opacity(0.82))
              Text(contact.role).font(.system(size: 12, weight: .medium)).foregroundColor(.black.opacity(0.42))
            }
            Spacer()
            Image(systemName: "chevron.right").foregroundColor(.black.opacity(0.2))
          }
          .padding(.vertical, 6)
        }
      }
    }
    .listStyle(.plain)
    .background(Color.clear)
  }
}
