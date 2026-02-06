//
//  SidebarListRow.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import SwiftData
import MapKit

struct SidebarListRow: View {
    let record: LocationRecord
    @Environment(VirtualLocationViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @State private var isEditing = false
    @State private var editedName = ""
    @State private var showingDeleteConfirmation = false
    @FocusState private var isTextFieldFocused: Bool

    var body: some View {
        VStack(alignment: .leading) {
            recordName
                .font(.headline)

            Text(record.formattedCoordinate)
                .font(.caption)
                .foregroundStyle(.secondary)
            if let category = record.mapKitPointOfInterestCategory.map(MKPointOfInterestCategory.init) {
                Text(category.description)
            }
        }
        .alert("Delete Record", isPresented: $showingDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                viewModel.deleteRecord(record, in: modelContext)
            }
        } message: {
            Text("Are you sure you want to delete '\(record.name)'? This action cannot be undone.")
        }
        .contextMenu {
            renameButton
            Divider()
            favoritesButton
            Divider()
            deleteButton
        }
        .swipeActions(edge: .leading) {
            favoritesButton
                .symbolVariant(.fill)
                .labelStyle(.iconOnly)
                .tint(.yellow)
        }
        .swipeActions(edge: .trailing) {
            deleteButton
                .symbolVariant(.fill)
                .labelStyle(.iconOnly)
        }
    }

    private var recordName: some View {
        Group {
            if isEditing {
                TextField("", text: $editedName)
                    .controlSize(.mini)
                    .foregroundStyle(viewModel.selectedItemId == record.id ? .white : .primary)
                    .textFieldStyle(.roundedBorder)
                    .focused($isTextFieldFocused)
                    .onAppear {
                        editedName = record.name
                        isTextFieldFocused = true
                    }
                    .onSubmit(confirmRename)
                    .onDisappear(perform: cancelRename)
            } else {
                Text(record.name)
            }
        }
        .onChange(of: isTextFieldFocused) {
            if !isTextFieldFocused {
                if editedName.isEmpty {
                    cancelRename()
                } else {
                    confirmRename()
                }
            }
        }
    }
    
    private var renameButton: some View {
        Group {
            if isEditing {
                Button("Done", systemImage: "checkmark", action: confirmRename)
            } else {
                Button("Rename", systemImage: "pencil", action: startRename)
            }
        }
    }
    
    private func startRename() {
        isEditing = true
        editedName = record.name
    }
    
    private func confirmRename() {
        if !editedName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            record.name = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
            do {
                try modelContext.save()
            } catch {
                print("Error saving renamed record: \(error)")
            }
        }
        isEditing = false
    }
    
    private func cancelRename() {
        isEditing = false
    }

    private var favoritesButton: some View {
        Group {
            if !record.isFavorite {
                Button("Add to Favorites", systemImage: "star") {
                    viewModel.addToFavorites(record, in: modelContext)
                }
            } else {
                Button("Remove from Favorites", systemImage: "star.slash") {
                    viewModel.removeFromFavorites(record, in: modelContext)
                }
            }
        }
    }

    private var deleteButton: some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            showingDeleteConfirmation = true
        }
    }
}
