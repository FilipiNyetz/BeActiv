//
//  HealthManager.swift
//  BeActiv
//
//  Created by Filipi Romão on 10/08/25.
//

import Foundation
import HealthKit

extension Date {
    static var startOfToday: Date {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: Date())
        return start
    }

    static var endOfToday: Date {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: Date())
        return calendar.date(byAdding: .day, value: 1, to: start)!
    }

    
    static var startOfWeek: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1 // Domingo
        let currentDate = Date()
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentDate)
        return calendar.date(from: components)!
    }

    static var endOfWeek: Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.firstWeekday = 1 // Domingo
        let start = Date.startOfWeek
        return calendar.date(byAdding: .day, value: 7, to: start)!
    }

    
}


class HealthManager: ObservableObject {
    
    
    let healthStore = HKHealthStore()
    
    @Published var activies: [String: Activity] = [:]
    
    @Published var workouts: [Workout] = []
    
    init(){
        let steps = HKQuantityType(.stepCount)
        let calories = HKQuantityType(.activeEnergyBurned)
        let workouts = HKObjectType.workoutType()
        let hearthRate = HKQuantityType(.heartRate)
        let distance = HKQuantityType(.distanceWalkingRunning)
        let healthTypes:Set = [steps, calories, workouts, hearthRate, distance]
        
        
        Task{
            do{
                try await healthStore.requestAuthorization(toShare: healthTypes, read: healthTypes)
                
            } catch {
                print("Error fetching data")
            }
        }
    }
 
    
    func fetchWorkout(){
        
        print(Date.startOfToday)
        print(Date.endOfToday)
        
        DispatchQueue.main.async {
            self.workouts.removeAll()
        }
        let workout = HKObjectType.workoutType()
        let quantityType = HKObjectType.quantityType(
            forIdentifier: .heartRate
        )!
        
        let timePredicate = HKQuery.predicateForSamples(
            withStart: Date.startOfToday,
            end: Date.endOfToday
        )

        let workoutPredicate = HKQuery.predicateForWorkouts(with: .other)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, workoutPredicate])
        
        let query = HKSampleQuery(sampleType: workout, predicate: predicate, limit: 25, sortDescriptors: nil){_, sample, error in
            
            guard let workouts = sample as? [HKWorkout] , error == nil else{
                print("error fetching todays workout data")
                return
            }
            var count: Int = 0
            for workout in workouts {
                print("Workout tipo: \(workout.workoutActivityType)")
                let duration = Int(workout.duration)/60
                count += duration
                print("Duração: \(count)")
                print("Início: \(workout.startDate)")
                print("Fim: \(workout.endDate)")
                print("Calorias: \(workout.totalEnergyBurned)")
                print(workout.allStatistics)
                print(workout)
                
                var calorias: Int = 0
                var distancia: Int = 0
                
                if let distance = workout.totalDistance?.doubleValue(for: .meter()) {
                    print("Distância: \(distance) metros")
                    distancia = Int(distance)
                }
                if let caloriesBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    calorias = Int(caloriesBurned)
                }
                let workoutSummary = Workout(id:UUID(),idWorkoutType: Int(workout.workoutActivityType.rawValue), duration: count, calories: calorias, distance: distancia)
                
                DispatchQueue.main.async {
                    self.workouts.append(workoutSummary)
                }
                
            }
            
        }
        healthStore.execute(query)
    }
    
    
    
    func fetchWorkoutByWeek(){
        
        print(Date.startOfWeek)
        print(Date.endOfWeek)
        
        DispatchQueue.main.async {
            self.workouts.removeAll()
        }
        
        let workout = HKObjectType.workoutType()
        
        let timePredicate = HKQuery.predicateForSamples(withStart: .startOfWeek, end: .endOfWeek)
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .other)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, workoutPredicate])
        let query = HKSampleQuery(sampleType: workout, predicate: predicate, limit: 10, sortDescriptors: nil){_, sample, error in
            
            guard let workouts = sample as? [HKWorkout], error == nil else {
                print("error fetching week running data")
                return
            }
            
            var count: Int = 0
            
            for workout in workouts{
                let duration = Int(workout.duration)/60
                count += duration
                print(workout.workoutActivityType.rawValue)
                print(Int(workout.duration)/60)
                print(workout.totalEnergyBurned)
                
                var calorias: Int = 0
                if let caloriesBurned = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) {
                    calorias = Int(caloriesBurned)
                }
                
                let workoutSummary = Workout(id:UUID(),idWorkoutType:Int(workout.workoutActivityType.rawValue), duration: count, calories: calorias, distance: 0)
                
                DispatchQueue.main.async {
                    self.workouts.append(workoutSummary)
                }
            }
            
            
            
        }
        healthStore.execute(query)
        
    }
    
    
    func fetchTodayCalories(){
        let calories = HKQuantityType(.activeEnergyBurned)
        
        let predicate = HKQuery.predicateForSamples(withStart: .startOfToday, end: .endOfToday)
        
        let query = HKStatisticsQuery(quantityType: calories, quantitySamplePredicate: predicate){_, result, error in
            guard let quantity = result?.sumQuantity(), error == nil else {
                print("error fetching todays calorie data")
                return
            }
            
            let caloriesBurned = quantity.doubleValue(for: .kilocalorie())
            let activity = Activity(id:1, title: "Today calories", subtitle: "Goal: 10.000", image: "flame", amount: "\(caloriesBurned)")
            
            DispatchQueue.main.async {
                self.activies["TodayCalories"] = activity
            }
            
            print(caloriesBurned)
            
        }
        healthStore.execute(query)
    }
}
