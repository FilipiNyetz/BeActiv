//
//  HomeView.swift
//  BeActiv
//
//  Created by Filipi Romão on 10/08/25.
//

import SwiftUI

struct HomeView: View {
    
    @ObservedObject var manager: HealthManager
    @State var timeViewWorkout = 0
    @State var selectedSearch: filterType = .week
    
    
    var body: some View {
        VStack{
            LazyVGrid(columns: Array(repeating: GridItem(spacing:20), count: 2)){
              
                VStack(alignment: .leading){
                    Picker("Choose", selection: $selectedSearch) {
                        ForEach(filterType.allCases, id: \.self){
                            Text($0.rawValue)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    if selectedSearch.rawValue == "Semanal"{
                       
                        Text("Aqui sera semanal")
                        ForEach(manager.workouts, id: \.id){workout in
                            WorkoutView(workout: workout)
                        }
                    }else{
                        Text("Aqui sera diario")
                        
                        ForEach(manager.workouts, id: \.id){workout in
                            WorkoutView(workout: workout)
                        }
                    }
                }
                
                
                
              
            }
            .padding(.horizontal)
        }
        .task{
            if selectedSearch.rawValue == "Semanal"{
                manager.fetchWorkoutByWeek()
            }else{
                print("Entra aqui no task else")
                manager.fetchWorkout()
            }
        }
        .onChange(of: selectedSearch) {
            Task {
                if selectedSearch == .week {
                    manager.fetchWorkoutByWeek()
                } else {
                    manager.fetchWorkout()
                }
            }
        }
    }
    
    enum filterType: String, CaseIterable {
        case week = "Semanal"
        case day = "Diario"
    }
    
}


