//
//  BeActivApp.swift
//  BeActiv Watch App
//
//  Created by Filipi Romão on 10/08/25.
//

import SwiftUI

@main
struct BeActiv_Watch_AppApp: App {
    
    @StateObject var manager = WorkoutManager()
    @StateObject var wcSessionDelegate = WatchWCSessionDelegate()
    
    var body: some Scene {
        WindowGroup {
            HomeViewWatch(manager: manager)
                .onAppear {
                    print("*** Phone Content View Appeared ***")
                    wcSessionDelegate.startSession()
                }
            
        }
    }
}
