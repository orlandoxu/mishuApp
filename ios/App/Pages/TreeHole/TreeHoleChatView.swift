import Combine
import SwiftUI

struct TreeHoleChatView: View {
  let initialMoodContent: String?

  private let horizontalPadding: CGFloat = 24
  private let inputChromeHeight: CGFloat = 112
  private let restingInputBottomPadding: CGFloat = 18
  private let focusedInputBottomPadding: CGFloat = 8

  @State private var messages: [TreeHoleChatMessage] = [
    TreeHoleChatMessage(
      id: "0",
      role: .ai,
      text: "嗨！我是暖暖，一名热爱运动的体校大学生。虽然平时忙着训练，但我更喜欢在这个小角落听你分享。无论生活中有多少烦恼，尽管和我说，我不怕闹，就怕你憋坏了！"
    )
  ]
  @State private var input = ""
  @State private var didAppendInitialMood = false
  @State private var keyboardHeight: CGFloat = 0
  @FocusState private var isInputFocused: Bool

  var body: some View {
    GeometryReader { geometry in
      ZStack(alignment: .top) {
        Image("img_emo_chat_bg")
          .resizable()
          .scaledToFill()
          .frame(
            width: geometry.size.width + geometry.safeAreaInsets.leading + geometry.safeAreaInsets.trailing,
            height: geometry.size.height + geometry.safeAreaInsets.top + geometry.safeAreaInsets.bottom
          )
          .ignoresSafeArea()

        VStack(spacing: 0) {
          NavHeader(title: "", topPadding: 8, bottomPadding: 0)

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
              .padding(.top, 26)
              .padding(.bottom, messagesBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
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
          }
        }

        TreeHoleChatInputBar(
          input: $input,
          isFocused: $isInputFocused
        ) {
          send()
        } onChangeTopic: {
          changeTopic()
        }
        .padding(.horizontal, horizontalPadding)
        .padding(.bottom, inputBottomPadding(safeAreaBottom: geometry.safeAreaInsets.bottom))
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .zIndex(2)
      }
    }
    .ignoresSafeArea(.keyboard, edges: .bottom)
    .navigationBarHidden(true)
    .onReceive(Self.keyboardTransitionPublisher) { transition in
      withAnimation(.easeOut(duration: transition.duration)) {
        keyboardHeight = transition.height
      }
    }
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

  private func inputBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
    if keyboardHeight > 0 {
      return keyboardHeight + focusedInputBottomPadding
    }
    return max(safeAreaBottom, Self.windowSafeAreaBottom) + restingInputBottomPadding
  }

  private func messagesBottomPadding(safeAreaBottom: CGFloat) -> CGFloat {
    inputChromeHeight + inputBottomPadding(safeAreaBottom: safeAreaBottom)
  }

  private static var windowSafeAreaBottom: CGFloat {
    guard
      let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
      let window = windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
    else { return 0 }
    return window.safeAreaInsets.bottom
  }

  private static var keyboardTransitionPublisher: AnyPublisher<KeyboardTransition, Never> {
    let keyboardFrameChange = NotificationCenter.default
      .publisher(for: UIResponder.keyboardWillChangeFrameNotification)
      .map { notification -> KeyboardTransition in
        KeyboardTransition(
          height: keyboardHeight(from: notification),
          duration: keyboardAnimationDuration(from: notification)
        )
      }

    let willHide = NotificationCenter.default
      .publisher(for: UIResponder.keyboardWillHideNotification)
      .map { notification in
        KeyboardTransition(
          height: 0,
          duration: keyboardAnimationDuration(from: notification)
        )
      }

    return Publishers.Merge(keyboardFrameChange, willHide)
      .eraseToAnyPublisher()
  }

  private static func keyboardHeight(from notification: Notification) -> CGFloat {
    guard
      let frame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
      let window = keyWindow
    else { return 0 }
    let convertedFrame = window.convert(frame, from: nil)
    return max(0, window.bounds.maxY - convertedFrame.minY)
  }

  private static var keyWindow: UIWindow? {
    guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene else {
      return nil
    }
    return windowScene.windows.first(where: { $0.isKeyWindow }) ?? windowScene.windows.first
  }

  private static func keyboardAnimationDuration(from notification: Notification) -> Double {
    let duration = notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double
    return duration ?? 0.25
  }
}

private struct KeyboardTransition {
  let height: CGFloat
  let duration: Double
}
