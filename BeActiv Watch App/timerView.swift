//
//  timerView.swift
//  BeActiv Watch App
//
//  Created by Filipi Romão on 11/08/25.
//

import SwiftUI

struct timerView: View {
    
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        VStack{
            HStack{
                Text(manager.formatTime(manager.elapsedTime))
            }
            NavigationLink(destination: HomeViewWatch(manager: manager)) {
                Image(systemName: "xmark.circle.fill")
            }.simultaneousGesture(TapGesture().onEnded {
                print("Vai parar")
                manager.endWorkout()
                print("\(manager.isActive)")
            })
            
            
        }
    }
}


