import SwiftUI

struct TreeHoleChatView: View {
  let initialMoodContent: String?

  @State private var messages: [TreeHoleChatMessage] = [
    TreeHoleChatMessage(
      id: "0",
      role: .ai,
      text: "嗨！我是暖暖，一名热爱运动的体校大学生。虽然平时忙着训练，但我更喜欢在这个小角落听你分享。无论生活中有多少烦恼，尽管和我说，我不怕闹，就怕你憋坏了！"
    )
  ]
  @State private var input = ""
  @State private var didAppendInitialMood = false

  var body: some View {
    ZStack {
      Image("img_emo_chat_bg")
        .resizable()
        .scaledToFill()
        .ignoresSafeArea()

      VStack(spacing: 0) {
        NavHeader(title: "", topPadding: 8, bottomPadding: 0)

        ScrollViewReader { proxy in
          ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
              ForEach(messages) { message in
                TreeHoleChatBubble(message: message, maxBubbleWidth: UIScreen.main.bounds.width * 0.75)
                  .id(message.id)
              }
            }
            .padding(.horizontal, 24)
            .padding(.top, 26)
            .padding(.bottom, 18)
          }
          .onChange(of: messages) { _ in
            scrollToBottom(proxy)
          }
          .onAppear {
            scrollToBottom(proxy)
          }
        }

        TreeHoleChatInputBar(input: $input) {
          send()
        } onChangeTopic: {
          changeTopic()
        }
        .padding(.horizontal, 24)
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
}
