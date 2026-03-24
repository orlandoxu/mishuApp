import SwiftUI
import UIKit

struct CameraPicker: UIViewControllerRepresentable {
  let onPick: (UIImage?) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(onPick: onPick)
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    picker.allowsEditing = false
    return picker
  }

  func updateUIViewController(_: UIImagePickerController, context _: Context) {}

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    let onPick: (UIImage?) -> Void

    init(onPick: @escaping (UIImage?) -> Void) {
      self.onPick = onPick
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      picker.dismiss(animated: true)
      if let image = info[.originalImage] as? UIImage {
        onPick(image)
      } else {
        onPick(nil)
      }
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      picker.dismiss(animated: true)
      onPick(nil)
    }
  }
}
