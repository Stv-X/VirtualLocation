//
//  VirtualLocationApp.swift
//  Virtual Location
//
//  Created by Steve on 2/3/26.
//

import SwiftUI
import SwiftData

@main
struct VirtualLocationApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [LocationRecord.self])
    }
}
