//
//  DreamCatchApp.swift
//  DreamCatch
//
//  Created by Simeon on 1/28/24.
//

import SwiftUI
import SwiftData

@main
struct DreamCatchApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: Dream.self) 
    }
}
