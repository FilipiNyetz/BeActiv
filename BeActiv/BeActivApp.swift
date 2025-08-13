//
//  BeActivApp.swift
//  BeActiv
//
//  Created by Filipi Romão on 10/08/25.
//

import SwiftUI

@main
struct BeActivApp: App {
    @StateObject var wcSessionDelegate = PhoneWCSessionDelegate()
    @StateObject var manager = HealthManager()
    
    var body: some Scene {
        WindowGroup {
            HomeView(manager: manager)
                .onAppear {
                        print("*** Phone Content View Appeared ***")
                        wcSessionDelegate.startSession()
                }
        }
    }
}
