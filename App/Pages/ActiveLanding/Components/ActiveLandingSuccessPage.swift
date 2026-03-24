import Lottie
import SwiftUI

struct ActiveLandingSuccessPage: View {
  let play: Bool

  var body: some View {
    VStack(spacing: 0) {
      Spacer().frame(height: 94)

      ActiveLandingLottieView(shouldPlay: play)
        .frame(width: 168, height: 168)

      Spacer().frame(height: 24)

      Text("设备激活成功")
        .font(.system(size: 54 / 2, weight: .bold))
        .foregroundColor(Color(hex: "0x2F3136"))

      Spacer()
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}

private struct ActiveLandingLottieView: UIViewRepresentable {
  let shouldPlay: Bool

  func makeUIView(context: Context) -> UIView {
    let container = UIView(frame: .zero)
    let animationView = LottieAnimationView()
    animationView.translatesAutoresizingMaskIntoConstraints = false
    animationView.contentMode = .scaleAspectFit
    animationView.loopMode = .playOnce
    animationView.backgroundBehavior = .pauseAndRestore

    if let animation = LottieAnimation.named("Success") {
      animationView.animation = animation
    }

    container.addSubview(animationView)
    NSLayoutConstraint.activate([
      animationView.leadingAnchor.constraint(equalTo: container.leadingAnchor),
      animationView.trailingAnchor.constraint(equalTo: container.trailingAnchor),
      animationView.topAnchor.constraint(equalTo: container.topAnchor),
      animationView.bottomAnchor.constraint(equalTo: container.bottomAnchor),
    ])

    context.coordinator.animationView = animationView
    return container
  }

  func updateUIView(_: UIView, context: Context) {
    guard let animationView = context.coordinator.animationView else { return }
    if shouldPlay, context.coordinator.lastShouldPlay == false {
      animationView.currentProgress = 0
      animationView.play()
    }
    context.coordinator.lastShouldPlay = shouldPlay
  }

  func makeCoordinator() -> Coordinator {
    Coordinator()
  }

  final class Coordinator {
    var animationView: LottieAnimationView?
    var lastShouldPlay: Bool = false
  }
}
