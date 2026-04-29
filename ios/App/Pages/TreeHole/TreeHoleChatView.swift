import SwiftUI

struct TreeHoleChatView: View {
  let initialMoodContent: String?

  private let horizontalPadding: CGFloat = 24
  private let headerContentHeight: CGFloat = 56
  private let headerBottomPadding: CGFloat = 10

  @State private var messages: [TreeHoleChatMessage] = [
    TreeHoleChatMessage(
      id: "0",
      role: .ai,
      text: "嗨！我是暖暖，一名热爱运动的体校大学生。虽然平时忙着训练，但我更喜欢在这个小角落听你分享。无论生活中有多少烦恼，尽管和我说，我不怕闹，就怕你憋坏了！"
    )
  ]
  @State private var input = ""
  @State private var didAppendInitialMood = false
  @FocusState private var isInputFocused: Bool

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        Image("img_emo_chat_bg")
          .resizable()
          .scaledToFill()
          .frame(width: geometry.size.width, height: geometry.size.height)
          .ignoresSafeArea()

        ScrollViewReader { proxy in
          ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
              ForEach(messages) { message in
                TreeHoleChatBubble(
                  message: message,
                  maxBubbleWidth: geometry.size.width * 0.75
                )
                .id(message.id)
              }
            }
            .padding(.horizontal, horizontalPadding)
            .padding(.top, messagesTopPadding(safeAreaTop: geometry.safeAreaInsets.top))
            .padding(.bottom, 18)
          }
          .contentShape(Rectangle())
          .simultaneousGesture(TapGesture().onEnded(dismissInput))
          .onChange(of: messages) { _ in
            scrollToBottom(proxy)
          }
          .onChange(of: isInputFocused) { focused in
            guard focused else { return }
            scrollToBottom(proxy)
          }
          .onAppear {
            scrollToBottom(proxy)
          }
        }

        NavHeader(title: "", topPadding: 8, bottomPadding: headerBottomPadding)
      }
      .safeAreaInset(edge: .bottom, spacing: 0) {
        TreeHoleChatInputBar(
          input: $input,
          isFocused: $isInputFocused
        ) {
          send()
        } onChangeTopic: {
          changeTopic()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, max(8, geometry.safeAreaInsets.bottom == 0 ? 12 : 0))
      }
    }
    .navigationBarHidden(true)
    .task {
      appendInitialMoodIfNeeded()
    }
  }

  private func send() {
    let trimmed = input.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return }
    input = ""
    isInputFocused = false
    messages.append(TreeHoleChatMessage(id: "\(Date().timeIntervalSince1970)-user", role: .user, text: trimmed))

    DispatchQueue.main.asyncAfter(deadline: .now() + 0.65) {
      messages.append(
        TreeHoleChatMessage(
          id: "\(Date().timeIntervalSince1970)-ai",
          role: .ai,
          text: "听起来你最近确实承受了不少压力。能跟我多说说具体发生了什么吗？我在听。"
        )
      )
    }
  }

  private func changeTopic() {
    dismissInput()
    messages.append(
      TreeHoleChatMessage(
        id: "\(Date().timeIntervalSince1970)-topic",
        role: .ai,
        text: "那我们先把心放轻一点。此刻你最想被理解的是哪一件小事？"
      )
    )
  }

  private func appendInitialMoodIfNeeded() {
    guard !didAppendInitialMood, let initialMoodContent, !initialMoodContent.isEmpty else { return }
    didAppendInitialMood = true
    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
      messages.append(
        TreeHoleChatMessage(
          id: "initial-mood",
          role: .ai,
          text: "我看到你写道：'\(initialMoodContent)'。听起来你现在心里一定很不好受，愿意具体跟我说说是因为什么吗？我在这里听着。"
        )
      )
    }
  }

  private func scrollToBottom(_ proxy: ScrollViewProxy) {
    guard let last = messages.last else { return }
    DispatchQueue.main.async {
      withAnimation(.easeOut(duration: 0.2)) {
        proxy.scrollTo(last.id, anchor: .bottom)
      }
    }
  }

  private func dismissInput() {
    isInputFocused = false
    UIApplication.shared.dismissKeyboard()
  }

  private func messagesTopPadding(safeAreaTop: CGFloat) -> CGFloat {
    safeAreaTop + headerContentHeight + headerBottomPadding + 18
  }
}
