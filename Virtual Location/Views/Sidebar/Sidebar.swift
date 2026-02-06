//
//  Sidebar.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import SwiftData
import MapKit

struct Sidebar: View {
    @Environment(VirtualLocationViewModel.self) private var viewModel
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<LocationRecord> { $0.isFavorite },
           sort: \LocationRecord.timestamp,
           order: .reverse) private var favorites: [LocationRecord]
    @Query(filter: #Predicate<LocationRecord> { !$0.isFavorite },
           sort: \LocationRecord.timestamp,
           order: .reverse) private var history: [LocationRecord]
    @State private var showManualCoordinate = false

    var body: some View {
        @Bindable var vm = viewModel
        List(selection: $vm.selectedItemId) {
            Section("Manual Coordinate", isExpanded: $showManualCoordinate) {
                VStack {
                    TextField("Latitude", text: $vm.manualLatitude)
                    TextField("Longitude", text: $vm.manualLongitude)
                    Button("Set Location") {
                        if let lat = Double(viewModel.manualLatitude),
                           let lon = Double(viewModel.manualLongitude) {
                            let coordinate = CLLocationCoordinate2D(latitude: lat, longitude: lon)
                            viewModel.updateSelection(name: "Manual Location", coordinate: coordinate)
                            viewModel.selectedItemId = nil
                            viewModel.resetManualCoordinate()
                        }
                    }
                    .buttonSizing(.flexible)
                    .buttonStyle(.glassProminent)
                    .disabled(viewModel.manualLatitude.isEmpty || viewModel.manualLongitude.isEmpty)
                }
                .textFieldStyle(.roundedBorder)
            }
            Section("Favorites") {
                ForEach(favorites, id: \.id) { record in
                    SidebarListRow(record: record)
                        .tag(record.id)
                }
            }
            Section("History") {
                ForEach(history, id: \.id) { record in
                    SidebarListRow(record: record)
                        .tag(record.id)
                }
            }
        }
        .searchable(
            text: $vm.searchQuery,
            isPresented: $vm.isSearching,
            placement: .sidebar,
            prompt: "Search places"
        )
        .searchSuggestions {
            ForEach(viewModel.searchResults, id: \.self) { completion in
                Button {
                    viewModel.handleSearchSelection(completion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(completion.title)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
    }
}
