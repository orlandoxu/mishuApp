import AVKit
import SwiftUI
import UIKit

// MARK: - MessageFilterType

/// 消息筛选类型
enum MessageFilterType: String, CaseIterable, Identifiable {
  case all = "全部" // 全部消息
  case trip = "行程报告" // 行程报告消息
  case video = "抓拍" // 视频/照片抓拍
  case vibration = "震动报警" // 震动/碰撞报警
  case sos = "SOS视频" // SOS 紧急求救视频
  case license = "抄牌提醒" // 违章抄牌提醒
  case binding = "设备绑定" // 设备绑定消息

  var id: String {
    rawValue
  }

  /// 筛选类型对应的后端消息子类型集合
  var subTypes: Set<MessageModel.SubType> {
    switch self {
    case .all: return []
    case .trip: return [.travelReport]
    case .video: return [.capture]
    case .vibration: return [.shakeAlarm]
    case .sos: return [.sos]
    case .license: return [.trafficPolice]
    case .binding: return [.unbind]
    }
  }

  /// 筛选类型对应的图标名称
  var icon: String {
    switch self {
    case .all: return "square.grid.2x2"
    case .trip: return "doc.text"
    case .video: return "video"
    case .vibration: return "exclamationmark.triangle"
    case .sos: return "sos.circle"
    case .license: return "text.viewfinder"
    case .binding: return "link"
    }
  }
}

// MARK: - VehicleMessageList

/// 车辆消息列表页面
/// 展示单个设备的所有消息记录，支持筛选、编辑、删除等操作
struct VehicleMessageList: View {
  // MARK: - Properties

  /// 设备 ID（IMEI）
  let deviceId: String

  /// 页面标题（通常为车牌号或设备昵称）
  let title: String

  /// 消息数据管理
  @ObservedObject private var store: MessageStore = .shared

  /// 当前筛选类型
  @State private var filterType: MessageFilterType = .all

  /// 是否显示筛选底部弹窗
  @State private var showFilter: Bool = false

  /// 筛选弹窗中的临时筛选类型
  @State private var tempFilterType: MessageFilterType = .all

  /// 是否显示视频播放器
  @State private var isVideoPlayerPresented = false

  /// 视频播放地址
  @State private var videoURL: URL?

  /// 是否处于编辑模式
  @State private var isEditing: Bool = false

  /// 已选中的消息 ID 集合（用于批量删除）
  @State private var selectedIds: Set<String> = []

  /// 是否显示更多菜单
  @State private var showMoreMenu: Bool = false

  /// 是否已经触发过进入页面 2 秒自动已读
  @State private var hasScheduledAutoRead: Bool = false

  // MARK: - Private Computed Properties

  /// 筛选后的消息列表（按时间倒序）
  private var messages: [MessageModel] {
    let all = store.recorderMessages(deviceId: deviceId).sorted(by: { $0.createAt > $1.createAt })
    if filterType == .all { return all }
    return all.filter { msg in
      guard let typedSubType = msg.typedSubType else { return false }
      return filterType.subTypes.contains(typedSubType)
    }
  }

  /// 消息列表是否为空
  private var isEmpty: Bool {
    messages.isEmpty
  }

  /// 是否显示空状态占位
  /// - 说明：同步中时不显示空状态，避免闪烁
  private var shouldShowEmptyOverlay: Bool {
    if store.isSyncing { return false }
    return isEmpty
  }

  /// 筛选是否激活（不等于"全部"）
  private var isFilterActive: Bool {
    filterType != .all
  }

  /// 底部安全区域高度（用于适配全面屏底部）
  private var safeAreaBottom: CGFloat {
    UIApplication.shared.windows.first?.safeAreaInsets.bottom ?? 0
  }

  // MARK: - Body

  var body: some View {
    ZStack {
      VStack(spacing: 0) {
        // 导航栏（包含标题、筛选按钮、更多菜单）
        NavHeader(title: title) {
          HStack(spacing: 16) {
            // 筛选按钮
            Button {
              tempFilterType = filterType
              showFilter = true
            } label: {
              Image("icon_message_filter")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(isFilterActive ? Color(hex: "0x06BAFF") : Color(hex: "0x333333"))
            }

            // 进入编辑模式
            Button {
              withAnimation {
                isEditing = true
              }
            } label: {
              Image("icon_message_edit")
                .resizable()
                .renderingMode(.template)
                .scaledToFit()
                .frame(width: 30, height: 30)
                .foregroundColor(Color(hex: "0x333333"))
            }
          }
        }

        // 消息列表区域
        VStack(spacing: 0) {
          Spacer().frame(height: 12)

          ScrollView {
            LazyVStack(spacing: 12) {
              ForEach(messages, id: \.id) { msg in
                HStack(spacing: 12) {
                  // 编辑模式下显示复选框
                  if isEditing {
                    Button {
                      if selectedIds.contains(msg.id) {
                        selectedIds.remove(msg.id)
                      } else {
                        selectedIds.insert(msg.id)
                      }
                    } label: {
                      Image(systemName: selectedIds.contains(msg.id) ? "checkmark.square.fill" : "square")
                        .font(.system(size: 24))
                        .foregroundColor(selectedIds.contains(msg.id) ? Color(hex: "0x06BAFF") : Color(hex: "0xCCCCCC"))
                    }
                  }

                  // 消息条目
                  MessageItem(
                    message: msg,
                    time: Date.messageRelativeTimeText(from: msg.createAt),
                    // 判断是否显示未读红点
                    // 业务逻辑：仅由数据库 status 字段决定是否未读
                    hasUnread: store.shouldShowUnreadDot(for: msg),
                    onTapMedia: {
                      if !isEditing {
                        handleTapMedia(msg)
                      }
                    }
                  )
                  // 点击消息条目（编辑模式下切换选中状态）
                  .onTapGesture {
                    if isEditing {
                      if selectedIds.contains(msg.id) {
                        selectedIds.remove(msg.id)
                      } else {
                        selectedIds.insert(msg.id)
                      }
                    }
                  }
                }
              }
            }
            .padding(16)
          }
        }
        .animation(.spring(response: 0.25, dampingFraction: 0.9), value: messages.map(\.id))
        .background(Color(hex: "0xF8F8F8"))
        .overlay(
          Group {
            if shouldShowEmptyOverlay {
              MessageEmptyView(title: "这里还没有消息呢")
            }
          }
        )

        // 编辑模式底部工具栏
        if isEditing {
          VStack(spacing: 0) {
            Divider()
            HStack {
              // 全选/取消全选按钮
              Button {
                if selectedIds.count == messages.count {
                  selectedIds.removeAll()
                } else {
                  selectedIds = Set(messages.map(\.id))
                }
              } label: {
                Text(selectedIds.count == messages.count && !messages.isEmpty ? "取消全选" : "全选")
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x06BAFF"))
                  .frame(minWidth: 80)
              }

              Spacer()

              HStack(spacing: 16) {
                // 取消编辑按钮
                Button {
                  withAnimation {
                    isEditing = false
                    selectedIds.removeAll()
                  }
                } label: {
                  Text("取消")
                    .font(.system(size: 18))
                    .foregroundColor(Color(hex: "0x333333"))
                    .frame(width: 90, height: 40)
                    .background(Color.white)
                    .cornerRadius(4)
                    .overlay(
                      RoundedRectangle(cornerRadius: 6)
                        .stroke(Color(hex: "0xDDDDDD"), lineWidth: 1)
                    )
                }

                // 删除选中消息按钮
                Button {
                  let idsToDelete = Array(selectedIds)
                  Task {
                    await store.deleteMessages(idsToDelete)
                    if messages.isEmpty {
                      isEditing = false
                    }
                    selectedIds.removeAll()
                  }
                } label: {
                  Text("删除")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
                    .frame(width: 90, height: 40)
                    .background(selectedIds.isEmpty ? Color(hex: "0xFF9999") : Color.red)
                    .cornerRadius(6)
                }
                .disabled(selectedIds.isEmpty)
              }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.white)
            .padding(.bottom, safeAreaBottom)
          }
          .transition(.move(edge: .bottom))
        }
      }
      .ignoresSafeArea()
      .background(Color.white.ignoresSafeArea())
      // 页面出现时同步消息数据
      .onAppear {
        Task {
          if SelfStore.shared.isLoggedIn {
            await store.syncLatest()
          }
        }
        if !hasScheduledAutoRead {
          hasScheduledAutoRead = true
          Task {
            await store.markRecorderMessagesAsRead(deviceId: deviceId)
          }
        }
      }

      // 筛选弹窗显示/隐藏处理
      .onChange(of: showFilter) { newValue in
        if newValue {
          BottomSheetCenter.shared.show {
            MessageFilterSheet(
              filterType: $filterType,
              tempFilterType: $tempFilterType,
              isPresented: $showFilter
            )
          }
        } else {
          BottomSheetCenter.shared.hide()
        }
      }

      // 视频全屏播放器
      .fullScreenCover(isPresented: $isVideoPlayerPresented) {
        if let url = videoURL {
          MessageVideoPlayerView(url: url, isPresented: $isVideoPlayerPresented)
        } else {
          Color.black
            .ignoresSafeArea()
            .onTapGesture {
              isVideoPlayerPresented = false
            }
        }
      }
    }
    .navigationBarHidden(true)
  }

  // MARK: - Private Methods

  /// 处理点击媒体（图片/视频）
  /// - Parameter message: 消息模型
  private func handleTapMedia(_ message: MessageModel) {
    // 根据媒体类型展示：图片用查看器，视频用播放器
    switch message.mediaKind {
    case .image:
      if let url = URL(string: message.coverUrl), !message.coverUrl.isEmpty {
        ImageViewerManager.shared.show(url: url)
      }
    case .video:
      guard let url = URL(string: message.mediaUrl), !message.mediaUrl.isEmpty else { return }
      videoURL = url
      isVideoPlayerPresented = true
    case .none:
      break
    }
  }
}

// MARK: - MessageFilterSheet

/// 消息筛选底部弹窗
private struct MessageFilterSheet: View {
  @Binding var filterType: MessageFilterType
  @Binding var tempFilterType: MessageFilterType
  @Binding var isPresented: Bool

  var body: some View {
    VStack(spacing: 0) {
      // 弹窗标题
      Text("筛选类别")
        .font(.system(size: 18, weight: .medium))
        .foregroundColor(Color(hex: "0x111111"))
        .padding(.top, 24)
        .padding(.bottom, 16)

      // 筛选选项列表
      ScrollView {
        VStack(spacing: 0) {
          ForEach(MessageFilterType.allCases.filter { $0 != .all }, id: \.self) { type in
            Button {
              tempFilterType = type
            } label: {
              HStack(spacing: 12) {
                Image(systemName: type.icon)
                  .font(.system(size: 18))
                  .foregroundColor(Color(hex: "0x333333"))
                  .frame(width: 24)

                Text(type.rawValue)
                  .font(.system(size: 16))
                  .foregroundColor(Color(hex: "0x333333"))

                Spacer()

                if tempFilterType == type {
                  Image(systemName: "checkmark")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(Color(hex: "0x06BAFF"))
                }
              }
              .padding(.horizontal, 20)
              .padding(.vertical, 16)
              .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if type != MessageFilterType.allCases.last {
              Divider().padding(.leading, 56)
            }
          }
        }
      }
      .frame(maxHeight: 320)

      // 底部按钮（重置、确定）
      HStack(spacing: 16) {
        // 重置按钮
        Button {
          tempFilterType = .all
          filterType = .all
          isPresented = false
          BottomSheetCenter.shared.hide()
        } label: {
          Text("重置")
            .font(.system(size: 16))
            .foregroundColor(Color(hex: "0x666666"))
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color.white)
            .cornerRadius(4)
            .overlay(
              RoundedRectangle(cornerRadius: 4)
                .stroke(Color(hex: "0xDDDDDD"), lineWidth: 1)
            )
        }

        // 确定按钮
        Button {
          filterType = tempFilterType
          isPresented = false
          BottomSheetCenter.shared.hide()
        } label: {
          Text("确定")
            .font(.system(size: 16))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(Color(hex: "0x06BAFF"))
            .cornerRadius(4)
        }
      }
      .padding(20)
      .padding(.bottom, safeAreaBottom)
    }
    .frame(maxWidth: .infinity)
    .background(Color.white)
    .cornerRadius(24)
    .onDisappear {
      if isPresented {
        isPresented = false
      }
    }
  }
}

// MARK: - MessageVideoPlayerView

/// 全屏视频播放器视图
private struct MessageVideoPlayerView: View {
  let url: URL
  @Binding var isPresented: Bool
  @State private var player: AVPlayer?

  var body: some View {
    ZStack(alignment: .topLeading) {
      if let player {
        VideoPlayer(player: player)
          .ignoresSafeArea()
      } else {
        Color.black.ignoresSafeArea()
      }

      // 关闭按钮
      Button {
        isPresented = false
      } label: {
        Image(systemName: "xmark")
          .font(.system(size: 16, weight: .bold))
          .foregroundColor(.white)
          .padding(12)
          .background(Color.black.opacity(0.6))
          .clipShape(Circle())
      }
      .padding(.leading, 16)
      .padding(.top, safeAreaTop + 12)
    }
    .onAppear {
      let newPlayer = AVPlayer(url: url)
      player = newPlayer
      newPlayer.play()
    }
    .onDisappear {
      player?.pause()
      player = nil
    }
  }
}
