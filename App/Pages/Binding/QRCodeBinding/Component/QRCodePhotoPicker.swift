import PhotosUI
import SwiftUI

struct PhotoPicker: UIViewControllerRepresentable {
  let onPick: (UIImage?) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onPick: onPick)
  }

  func makeUIViewController(context: Context) -> PHPickerViewController {
    var configuration = PHPickerConfiguration(photoLibrary: .shared())
    configuration.filter = .images
    configuration.selectionLimit = 1
    let picker = PHPickerViewController(configuration: configuration)
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_: PHPickerViewController, context _: Context) {}

  final class Coordinator: NSObject, PHPickerViewControllerDelegate {
    let onPick: (UIImage?) -> Void

    init(onPick: @escaping (UIImage?) -> Void) {
      self.onPick = onPick
    }

    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
      picker.dismiss(animated: true)
      guard let itemProvider = results.first?.itemProvider else {
        onPick(nil)
        return
      }
      if itemProvider.canLoadObject(ofClass: UIImage.self) {
        itemProvider.loadObject(ofClass: UIImage.self) { [weak self] object, _ in
          DispatchQueue.main.async {
            self?.onPick(object as? UIImage)
          }
        }
      } else {
        onPick(nil)
      }
    }
  }
}
