//
//  MusicTrackingApp.swift
//  MusicTracking
//
//  Created by Jacob Rees on 01/07/2025.
//

import SwiftUI
import CoreData

@main
struct MusicTrackingApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
