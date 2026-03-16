// TDV-38: Create a profile editor for customizations and photos
// ProfilePhotoGridView.swift
// Toodles

import SwiftUI

struct ProfilePhoto: Identifiable {
    let id = UUID()
    var image: UIImage
    var isNew: Bool = false
}

struct ProfilePhotoGridView: View {
    @Binding var photos: [ProfilePhoto]
    let onAddPhoto: () -> Void
    private let maxPhotos = 6
    private let columns = [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(photos) { photo in
                PhotoCell(image: photo.image) {
                    removePhoto(photo)
                }
            }
            if photos.count < maxPhotos {
                AddPhotoCell(action: onAddPhoto)
            }
        }
        .padding(.vertical, 8)
    }

    private func removePhoto(_ photo: ProfilePhoto) {
        photos.removeAll { $0.id == photo.id }
    }
}

// MARK: - Photo Cell
private struct PhotoCell: View {
    let image: UIImage
    let onRemove: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 100, height: 130)
                .clipped()
                .cornerRadius(10)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundColor(.white)
                    .background(Color.black.opacity(0.6))
                    .clipShape(Circle())
            }
            .padding(4)
        }
    }
}

// MARK: - Add Photo Cell
private struct AddPhotoCell: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [6]))
                    .frame(width: 100, height: 130)
                Image(systemName: "plus")
                    .font(.title2)
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    ProfilePhotoGridView(photos: .constant([]), onAddPhoto: {})
}
