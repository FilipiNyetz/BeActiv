//
//  HomeViewWatch.swift
//  BeActiv Watch App
//
//  Created by Filipi Romão on 11/08/25.
//

import SwiftUI

struct HomeViewWatch: View {
    
    @ObservedObject var manager: WorkoutManager
    
    var body: some View {
        NavigationStack {
            HStack{
                Button(action: {
                    print("Vai finalizar")
                    manager.endWorkout()
                    print("\(manager.isActive)")
                }, label: {
                    Image(systemName: "xmark.circle.fill")
                })
                
                Button(action: {
                    print("Vai pausar")
                    manager.pause()
                }, label: {
                    Image(systemName: "pause.circle.fill")
                })
                
                
                NavigationLink(destination: MetricsView(workoutManager:manager)) {
                    Text("Go")
                }.simultaneousGesture(TapGesture().onEnded {
                    print("Vai iniciar")
                    manager.startWorkout(workoutType: .running)
                    
                    
                    print("\(manager.isActive)")
                })
                
                
            }
        }
            .onAppear {
                manager.requestAuthorization()
            }
        
    }
}

