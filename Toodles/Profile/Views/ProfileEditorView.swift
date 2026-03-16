// TDV-60: Build ProfileEditorView and ProfileEditorViewModel with MVVM binding
// ProfileEditorView.swift
// Toodles
//
// Subtask of TDV-38: Create a profile editor for customizations and photos
// Implements the main SwiftUI profile editor view with MVVM binding.

import SwiftUI
import PhotosUI

struct ProfileEditorView: View {
    @StateObject private var viewModel = ProfileEditorViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                // MARK: - Profile Photo Section
                Section {
                    ProfilePhotoGridView(
                        photos: $viewModel.selectedPhotos,
                        onAddPhoto: { viewModel.showPhotoPicker = true }
                    )
                } header: {
                    Text("Photos")
                } footer: {
                    Text("Add up to 6 photos. Your first photo will be your main profile picture.")
                        .font(.caption)
                }

                // MARK: - Basic Info Section
                Section("About You") {
                    HStack {
                        Text("Name").foregroundColor(.secondary)
                        Spacer()
                        TextField("Display name", text: $viewModel.displayName)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Pronouns").foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $viewModel.pronouns) {
                            ForEach(ProfilePronouns.allCases, id: \.self) { pronoun in
                                Text(pronoun.displayText).tag(pronoun)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }

                // MARK: - Bio Section
                Section("Bio") {
                    TextEditor(text: $viewModel.bio)
                        .frame(minHeight: 100)
                    HStack {
                        Spacer()
                        Text("\(viewModel.bio.count)/300")
                            .font(.caption)
                            .foregroundColor(viewModel.bio.count > 280 ? .orange : .secondary)
                    }
                }

                // MARK: - Interests Section
                Section("Interests") {
                    InterestsPickerView(selectedInterests: $viewModel.selectedInterests)
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        Task { await viewModel.saveProfile() }
                    }
                    .fontWeight(.semibold)
                    .disabled(!viewModel.hasChanges || viewModel.isSaving)
                }
            }
            .sheet(isPresented: $viewModel.showPhotoPicker) {
                PhotoPickerView(selectedPhotos: $viewModel.selectedPhotos)
            }
        }
        .task { await viewModel.loadCurrentProfile() }
    }
}

#Preview { ProfileEditorView() }
