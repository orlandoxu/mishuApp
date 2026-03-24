final class DeinitDetector {
  let onDeinit: () -> Void

  init(_ onDeinit: @escaping () -> Void) {
    self.onDeinit = onDeinit
  }

  deinit {
    onDeinit()
  }
}
