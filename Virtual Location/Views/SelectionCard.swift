//
//  SelectionCard.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import SwiftData
import MapKit

struct SelectionCard: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(VirtualLocationViewModel.self) private var viewModel
    @Environment(DeviceConnectionManager.self) private var deviceConnectionManager
    @AppStorage("cliDirectory") private var cliDirectory: String = ""
    let coordinate: CLLocationCoordinate2D

    var body: some View {
        @Bindable var vm = viewModel
        VStack {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        Text(viewModel.selectedName.isEmpty ? "Selected Location" : viewModel.selectedName)
                            .font(.headline)
                        Button("", systemImage: "binoculars") {
                            viewModel.updateMapPosition(center: coordinate)
                        }
                        .buttonBorderShape(.circle)
                        .labelStyle(.iconOnly)
                    }
                    Text(String(format: "Lat %.6f, Lon %.6f", coordinate.latitude, coordinate.longitude))
                        .contentTransition(.numericText(value: coordinate.latitude))
                        .contentTransition(.numericText(value: coordinate.longitude))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button("Cancel", systemImage: "xmark", action: viewModel.clearSelection)
                    .buttonBorderShape(.circle)
                    .labelStyle(.iconOnly)
            }
            HStack {
                Button("Send to Device", systemImage: "location.fill") {
                    Task {
                        await sendSelection()
                    }
                }
                .buttonStyle(.borderedProminent)
                Button("Add to Favorites", systemImage: "star", action: saveFavorite)
            }
            .buttonBorderShape(.capsule)
        }
        .alert("Tunnel connection failed", isPresented: $vm.showTunnelConnectionFailedAlert) {}
        .padding()
        .glassEffect(.regular, in: .rect(cornerRadius: 16))
        .frame(maxWidth: 280)
    }
    
    private func sendSelection() async {
        guard let selectedCoordinate = viewModel.selectedCoordinate else { return }
        guard deviceConnectionManager.connectionOption != nil else {
            viewModel.showTunnelConnectionFailedAlert = true
            return
        }
        let record = LocationRecord(
            name: viewModel.selectedName.isEmpty ? "Pinned" : viewModel.selectedName,
            isFavorite: false,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            timestamp: Date(),
            deviceId: deviceConnectionManager.selectedDevice?.uniqueDeviceId,
            mapKitPointOfInterestCategory: viewModel.selectedMapItem?.pointOfInterestCategory?.rawValue
        )
        modelContext.insert(record)
        do {
            try await deviceConnectionManager.setVirtualLocation(
                coordinate: selectedCoordinate,
                deviceId: deviceConnectionManager.selectedDevice?.uniqueDeviceId
            )
        } catch {
            deviceConnectionManager.deviceLastError = error.localizedDescription
        }
    }
    
    private func saveFavorite() {
        guard let selectedCoordinate = viewModel.selectedCoordinate else { return }
        let record = LocationRecord(
            name: viewModel.selectedName.isEmpty ? "Pinned" : viewModel.selectedName,
            isFavorite: true,
            latitude: selectedCoordinate.latitude,
            longitude: selectedCoordinate.longitude,
            timestamp: Date(),
            mapKitPointOfInterestCategory: viewModel.selectedMapItem?.pointOfInterestCategory?.rawValue
        )
        modelContext.insert(record)
    }
}

extension MKPointOfInterestCategory {
    var description: LocalizedStringKey {
        return LocalizedStringKey("MKPointOfInterestCategory.\(self.rawValue)")
    }
    
    var group: MKPointOfInterestCategoryGroup {
        switch self {
            // Arts and culture
        case .museum, .musicVenue, .theater:
            return .artsAndCulture
            
            // Education
        case .library, .planetarium, .school, .university:
            return .education
            
            // Entertainment
        case .movieTheater, .nightlife:
            return .entertainment
            
            // Health and safety
        case .fireStation, .hospital, .pharmacy, .police:
            return .healthAndSafety
            
            // Historical and cultural landmarks
        case .castle, .fortress, .landmark, .nationalMonument:
            return .historicalAndCulturalLandmarks
            
            // Food and drink
        case .bakery, .brewery, .cafe, .distillery, .foodMarket, .restaurant, .winery:
            return .foodAndDrink
            
            // Personal services
        case .animalService, .atm, .automotiveRepair, .bank, .beauty, .evCharger,
                .fitnessCenter, .laundry, .mailbox, .postOffice, .restroom, .spa, .store:
            return .personalServices
            
            // Parks and recreation
        case .amusementPark, .aquarium, .beach, .campground, .fairground,
                .marina, .nationalPark, .park, .rvPark, .zoo:
            return .parksAndRecreation
            
            // Sports
        case .baseball, .basketball, .bowling, .goKart, .golf, .hiking, .miniGolf,
                .rockClimbing, .skatePark, .skating, .skiing, .soccer, .stadium, .tennis, .volleyball:
            return .sports
            
            // Travel
        case .airport, .carRental, .conventionCenter, .gasStation, .hotel, .parking, .publicTransport:
            return .travel
            
            // Water sports
        case .fishing, .kayaking, .surfing, .swimming:
            return .waterSports
            
        default:
            return .unknown
        }
    }
    
    var image: String {
        switch self {
            // Arts and culture
        case .museum: return "building.columns"
        case .musicVenue: return "music.note.house"
        case .theater: return "theatermasks"
            
            // Education
        case .library: return "books.vertical"
        case .planetarium: return "globe"
        case .school: return "graduationcap"
        case .university: return "building.columns.fill"
            
            // Entertainment
        case .movieTheater: return "popcorn"
        case .nightlife: return "moon.stars"
            
            // Health and safety
        case .fireStation: return "flame"
        case .hospital: return "cross.case"
        case .pharmacy: return "pills"
        case .police: return "shield"
            
            // Historical and cultural landmarks
        case .castle: return "building.2" // SF Symbols 中没有专门城堡，使用通用建筑
        case .fortress: return "shield.lefthalf.filled"
        case .landmark: return "star"
        case .nationalMonument: return "building.columns"
            
            // Food and drink
        case .bakery: return "birthday.cake" // 或 "bread" (SF Symbol 6+)
        case .brewery: return "mug"
        case .cafe: return "cup.and.saucer"
        case .distillery: return "drop.triangle"
        case .foodMarket: return "basket"
        case .restaurant: return "fork.knife"
        case .winery: return "wineglass"
            
            // Personal services
        case .animalService: return "pawprint"
        case .atm: return "banknote"
        case .automotiveRepair: return "wrench.and.screwdriver"
        case .bank: return "building.columns"
        case .beauty: return "scissors"
        case .evCharger: return "bolt.car"
        case .fitnessCenter: return "dumbbell"
        case .laundry: return "washer"
        case .mailbox: return "envelope"
        case .postOffice: return "mail.stack"
        case .restroom: return "figure.dress.line.vertical.figure"
        case .spa: return "sparkles"
        case .store: return "bag"
            
            // Parks and recreation
        case .amusementPark: return "trophy" // 或 "ferris.wheel" (如果支持较新版本)
        case .aquarium: return "fish"
        case .beach: return "umbrella"
        case .campground: return "tent"
        case .fairground: return "flag.2.crossed"
        case .marina: return "sailboat"
        case .nationalPark: return "tree"
        case .park: return "tree"
        case .rvPark: return "bus"
        case .zoo: return "tortoise"
            
            // Sports
        case .baseball: return "figure.baseball"
        case .basketball: return "basketball"
        case .bowling: return "figure.bowling"
        case .goKart: return "car.side"
        case .golf: return "figure.golf"
        case .hiking: return "figure.hiking"
        case .miniGolf: return "flag.filled.and.flag.crossed"
        case .rockClimbing: return "figure.climbing"
        case .skatePark: return "figure.skating" // 近似
        case .skating: return "figure.skating"
        case .skiing: return "figure.skiing.downhill"
        case .soccer: return "soccerball"
        case .stadium: return "sportscourt"
        case .tennis: return "tennisball"
        case .volleyball: return "volleyball"
            
            // Travel
        case .airport: return "airplane"
        case .carRental: return "key"
        case .conventionCenter: return "person.3"
        case .gasStation: return "fuelpump"
        case .hotel: return "bed.double"
        case .parking: return "parkingsign"
        case .publicTransport: return "bus.doubledecker"
            
            // Water sports
        case .fishing: return "figure.fishing"
        case .kayaking: return "figure.kayaking" // SF Symbols 5+
        case .surfing: return "figure.surfing"
        case .swimming: return "figure.pool.swim"
            
        default:
            return "mappin" // 默认图标
        }
    }
}

public enum MKPointOfInterestCategoryGroup: String, CaseIterable {
    case artsAndCulture
    case education
    case entertainment
    case healthAndSafety
    case historicalAndCulturalLandmarks
    case foodAndDrink
    case personalServices
    case parksAndRecreation
    case sports
    case travel
    case waterSports
    case unknown
}

extension MKPointOfInterestCategoryGroup {
    var color: Color {
        switch self {
        case .artsAndCulture: .cyan
        case .education: .brown
        case .entertainment: .indigo
        case .healthAndSafety: .pink
        case .historicalAndCulturalLandmarks: .brown
        case .foodAndDrink: .orange
        case .personalServices: .orange
        case .parksAndRecreation: .mint
        case .sports: .green
        case .travel: .purple
        case .waterSports: .blue
        case .unknown: .gray
        }
    }
}
