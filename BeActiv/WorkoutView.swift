//
//  WorkoutView.swift
//  BeActiv
//
//  Created by Filipi Romão on 12/08/25.
//

import SwiftUI

struct Workout: Identifiable{
    let id: UUID
    let idWorkoutType: Int
    let duration: Int
    let calories: Int
    let distance: Int
    let frequencyHeart: Int
}

struct WorkoutView: View {
    
    @State var workout: Workout
    
    var body: some View {
        
        VStack{
            if workout.idWorkoutType == 4{
                Text("BeachTraining")
            }
            Text("Time:\(workout.duration)")
            Text("Calories:\(workout.calories)")
            Text("Distancias:\(workout.distance)")
            Text("frequencyHeart:\(workout.frequencyHeart)")
        }
        .background(Color.gray.opacity(0.4))
        .frame(width: 300, height: 100)
        .cornerRadius(20)
        
    }
}


