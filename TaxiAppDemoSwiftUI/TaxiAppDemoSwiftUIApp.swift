//
//  TaxiAppDemoSwiftUIApp.swift
//  TaxiAppDemoSwiftUI
//
//  Created by Arslan Abdullaev on 11.02.2022.
//

import SwiftUI
import Firebase

@main
struct TaxiAppDemoSwiftUIApp: App {
    
    init() {
        FirebaseApp.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
