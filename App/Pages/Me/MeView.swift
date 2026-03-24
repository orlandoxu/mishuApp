import Kingfisher
import SwiftUI

// DONE-AI: 调整“我的”页 UI，使用项目内资源与一致的卡片布局
struct MeView: View {
  private let appNavigation = AppNavigationModel.shared
  @StateObject private var viewModel: MeViewModel = .init()
  @ObservedObject private var selfStore: SelfStore = .shared

  var body: some View {
    ZStack(alignment: .top) {
      ThemeColor.gray100.ignoresSafeArea()

      ScrollView(.vertical, showsIndicators: false) {
        VStack(spacing: 16) {
          MeHeaderView().background(Color.white)

          VStack(spacing: 12) {
            // 服务与订单
            sectionHeader(title: "服务与订单")
            serviceCard

            // 常规设置
            sectionHeader(title: "常规设置")
            settingsCard

            // TODO: 其他信息，下个版本开发
            // sectionHeader(title: "其他信息")
            // otherInfoCard

            // if viewModel.isLoading {
            //   ProgressView()
            //     .frame(maxWidth: .infinity)
            //     .padding(.top, 10)
            // }

            if let message = viewModel.errorMessage, !message.isEmpty {
              Text(message)
                .foregroundColor(.red)
                .font(.system(size: 14, weight: .medium))
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.white)
                .cornerRadius(12)
            }

            LogoutButton().padding(.top, 20)

            Spacer(minLength: 40)
          }
          .padding(.horizontal, 16)
          .padding(.bottom, 100)
        }
      }

      LoginBackgroundView(bgColor: Color.clear)
        .ignoresSafeArea()
        .allowsHitTesting(false)
    }
    .edgesIgnoringSafeArea(.top)
    .navigationBarHidden(true)
    .navigationBarBackButtonHidden(true)
    .onAppear { Task { await viewModel.load() } }
  }

  private func sectionHeader(title: String) -> some View {
    Text(title)
      .font(.system(size: 14, weight: .regular))
      .foregroundColor(Color(hex: "0x666666"))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.top, 8)
      .padding(.bottom, 0)
      .padding(.leading, 4)
  }

  // 移除旧的组件实现
  // private var topCard: some View { ... }
  // private var displayName: String { ... }
  // private var statsCard: some View { ... }
  // private func statItem(icon: String, title: String, value: String) -> some View { ... }

  private var serviceCard: some View {
    MeMenuCard {
      MeMenuRow(icon: "icon_me_order", title: "我的订单", rightContent: {
        HStack(spacing: 4) {
          // 先去掉这个生效中，因为这儿如果要显示生效中，需要深度思考怎么才算生效中
          // Text("生效中")
          //   .font(.system(size: 14, weight: .regular))
          //   .foregroundColor(Color(hex: "0x34C759")) // Green

          Image("icon_more_arrow")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundColor(Color(hex: "0xCCCCCC"))
        }
      }) {
        appNavigation.push(.orderList)
      }
    }
  }

  private var settingsCard: some View {
    MeMenuCard {
      MeMenuRow(icon: "icon_me_setting", title: "APP设置") {
        appNavigation.push(.meSetting)
      }
      MeMenuDivider()
      MeMenuRow(icon: "icon_me_service", title: "在线客服") {
        let url = AppConst.buildWeChatServiceURL(
          userId: SelfStore.shared.selfUser?.userId,
          nickName: SelfStore.shared.selfUser?.nickname
        )
        appNavigation.push(.web(url: url, title: "在线客服", hideNav: false, notice: "如果发送消息失败，请切换为手机网络"))
      }
    }
  }

  private var otherInfoCard: some View {
    MeMenuCard {
      // TODO: 推荐给好友，下个版本开发
      MeMenuRow(icon: "icon_me_share", title: "推荐给好友") {
        ToastCenter.shared.show("功能开发中")
      }
      // MeMenuDivider()
      MeMenuRow(icon: "icon_me_dev", title: "环境配置", rightContent: {
        HStack(spacing: 4) {
          Text("生产环境")
            .font(.system(size: 14, weight: .regular))
            .foregroundColor(Color(hex: "0x999999"))

          Image("icon_more_arrow")
            .resizable()
            .scaledToFit()
            .frame(width: 12, height: 12)
            .foregroundColor(Color(hex: "0xCCCCCC"))
        }
      }) {
        ToastCenter.shared.show("功能开发中")
      }
    }
  }
}
