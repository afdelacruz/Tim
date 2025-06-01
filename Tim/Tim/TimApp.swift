//
//  TimApp.swift
//  Tim
//
//  Created by Andrew De la Cruz on 5/31/25.
//

import SwiftUI

@main
struct TimApp: App {
    
    init() {
        // Suppress constraint warnings from Plaid Link SDK
        UserDefaults.standard.set(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
