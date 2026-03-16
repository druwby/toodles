// TDV-38: Create a profile editor for customizations and photos
// ProfileEditorView.swift
// Toodles

import SwiftUI
import PhotosUI

struct ProfileEditorView: View {
    @StateObject private var viewModel = ProfileEditorViewModel()
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section {
                    ProfilePhotoGridView(
                        photos: $viewModel.selectedPhotos,
                        onAddPhoto: { viewModel.showPhotoPicker = true }
                    )
                } header: { Text("Photos") } footer: {
                    Text("Add up to 6 photos. Your first photo will be your main profile picture.")
                        .font(.caption)
                }

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
                            ForEach(ProfilePronouns.allCases, id: \.self) { p in
                                Text(p.displayText).tag(p)
                            }
                        }.pickerStyle(.menu)
                    }
                }

                Section("Bio") {
                    TextEditor(text: $viewModel.bio).frame(minHeight: 100)
                    HStack {
                        Spacer()
                        Text("\(viewModel.bio.count)/300").font(.caption)
                            .foregroundColor(viewModel.bio.count > 280 ? .orange : .secondary)
                    }
                }

                Section("Interests") {
                    InterestsPickerView(selectedInterests: $viewModel.selectedInterests)
                }

                Section("Match Preferences") {
                    HStack {
                        Text("Looking for").foregroundColor(.secondary)
                        Spacer()
                        Picker("", selection: $viewModel.lookingFor) {
                            ForEach(RelationshipIntent.allCases, id: \.self) { i in
                                Text(i.displayText).tag(i)
                            }
                        }.pickerStyle(.menu)
                    }
                }

                Section("Account") {
                    NavigationLink("Notification Settings") { NotificationSettingsView() }
                    NavigationLink("Privacy & Safety") { PrivacySettingsView() }
                    Button(role: .destructive) {
                        viewModel.showDeleteConfirmation = true
                    } label: { Text("Delete Account") }
                }
            }
            .navigationTitle("Edit Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") { Task { await viewModel.saveProfile() } }
                        .fontWeight(.semibold)
                        .disabled(!viewModel.hasChanges || viewModel.isSaving)
                }
            }
            .alert("Profile Saved", isPresented: $viewModel.showSuccessAlert) { Button("OK") { dismiss() } }
            .alert("Error", isPresented: $viewModel.showErrorAlert) { Button("OK") {} } message: { Text(viewModel.errorMessage) }
            .sheet(isPresented: $viewModel.showPhotoPicker) { PhotoPickerView(selectedPhotos: $viewModel.selectedPhotos) }
        }
        .task { await viewModel.loadCurrentProfile() }
    }
}

#Preview { ProfileEditorView() }
