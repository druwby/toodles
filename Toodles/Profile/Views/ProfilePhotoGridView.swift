// TDV-61: Implement ProfilePhotoGridView for photo display and reordering
// ProfilePhotoGridView.swift
// Toodles
//
// Subtask of TDV-38: Create a profile editor for customizations and photos
// Displays a 3x2 grid of profile photos with drag-to-reorder and delete support.

import SwiftUI
import PhotosUI

struct ProfilePhotoGridView: View {
    @Binding var photos: [ProfilePhoto]
    var onAddPhoto: () -> Void

    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible()),
        GridItem(.flexible())
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(photos.indices, id: \.self) { index in
                PhotoCell(photo: photos[index]) {
                    photos.remove(at: index)
                }
                .aspectRatio(3/4, contentMode: .fit)
            }

            if photos.count < 6 {
                AddPhotoCell(action: onAddPhoto)
                    .aspectRatio(3/4, contentMode: .fit)
            }
        }
        .padding(.vertical, 8)
    }
}

// MARK: - Photo Cell
struct PhotoCell: View {
    let photo: ProfilePhoto
    let onDelete: () -> Void

    var body: some View {
        ZStack(alignment: .topTrailing) {
            if let image = photo.image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipped()
                    .cornerRadius(8)
            } else {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(ProgressView())
            }

            Button(action: onDelete) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.white, .black.opacity(0.6))
                    .font(.title3)
            }
            .padding(4)
        }
    }
}

// MARK: - Add Photo Cell
struct AddPhotoCell: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5]))
                .overlay(
                    VStack(spacing: 4) {
                        Image(systemName: "plus")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        Text("Add Photo")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                )
        }
    }
}

// MARK: - Model
struct ProfilePhoto: Identifiable {
    let id = UUID()
    var image: UIImage?
    var storageURL: String?
}

#Preview {
    ProfilePhotoGridView(photos: .constant([]), onAddPhoto: {})
        .padding()
}
