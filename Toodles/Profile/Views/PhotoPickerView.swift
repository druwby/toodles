// TDV-62: Integrate PhotoPickerView and InterestsPickerView into profile editor
// PhotoPickerView.swift
// Toodles
//
// Subtask of TDV-38: Create a profile editor for customizations and photos
// UIViewControllerRepresentable wrapper around PHPickerViewController
// for selecting profile photos from the user's photo library.

import SwiftUI
import PhotosUI

struct PhotoPickerView: UIViewControllerRepresentable {
    @Binding var selectedPhotos: [ProfilePhoto]
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration(photoLibrary: .shared())
        config.selectionLimit = max(0, 6 - selectedPhotos.count)
        config.filter = .images
        config.preferredAssetRepresentationMode = .current

        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            guard !results.isEmpty else { return }

            let group = DispatchGroup()
            var newPhotos: [ProfilePhoto] = []

            for result in results {
                guard result.itemProvider.canLoadObject(ofClass: UIImage.self) else { continue }
                group.enter()
                result.itemProvider.loadObject(ofClass: UIImage.self) { object, error in
                    defer { group.leave() }
                    if let image = object as? UIImage {
                        newPhotos.append(ProfilePhoto(image: image))
                    }
                }
            }

            group.notify(queue: .main) {
                self.parent.selectedPhotos.append(contentsOf: newPhotos)
            }
        }
    }
}
