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
        
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
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
                let workoutSummary = Workout(id:UUID(),idWorkoutType: Int(workout.workoutActivityType.rawValue), duration: count, calories: calorias, distance: distancia, frequencyHeart: 0)
                
                DispatchQueue.main.async {
                    self.workouts.append(workoutSummary)
                }
                
            }
            
        }
        healthStore.execute(query)
    }
    
    
    
    func fetchWorkoutByWeek() {
        
        print(Date.startOfWeek)
        print(Date.endOfWeek)
        
        DispatchQueue.main.async {
            self.workouts.removeAll()
        }
        
        let workoutType = HKObjectType.workoutType()
        
        // Predicados para semana e tipo de treino
        let timePredicate = HKQuery.predicateForSamples(withStart: .startOfWeek, end: .endOfWeek)
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .soccer)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, workoutPredicate])
        
        // Query principal de workouts
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 10, sortDescriptors: nil) { _, samples, error in
            
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Erro ao buscar workouts da semana")
                return
            }
            
            for workout in workouts {
                let durationMinutes = Int(workout.duration) / 60
                
                // Calorias
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                
                // Distância
                let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
                
                var avgHeartRate: Double = 0
                
                // Frequência cardíaca média
                if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
                    let hrPredicate = HKQuery.predicateForObjects(from: workout)
                    let hrQuery = HKSampleQuery(sampleType: heartRateType, predicate: hrPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                        
                        
                        if let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty {
                            let hrValues = hrSamples.map { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                            avgHeartRate = hrValues.reduce(0, +) / Double(hrValues.count)
                        }
                        
                        
                    }
                    self.healthStore.execute(hrQuery)
                }
                
                if let v02MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
                    let v02MaxPredicate = HKQuery.predicateForObjects(from: workout)
                    let v02MaxQuery = HKSampleQuery(sampleType: v02MaxType, predicate: v02MaxPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                        
                        var v02Max: Double = 0
                        
                        if let v02MaxSamples = samples as? [HKQuantitySample], !v02MaxSamples.isEmpty {
                            let v02MaxValues = v02MaxSamples.map {
                                $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                            v02Max = v02MaxValues.reduce(0, +) / Double(v02MaxValues.count)
                        }
                        
                    }
                    self.healthStore.execute(v02MaxQuery)
                    
                }
                let workoutSummary = Workout(
                    id: UUID(),
                    idWorkoutType: Int(workout.workoutActivityType.rawValue),
                    duration: durationMinutes,
                    calories: Int(calories),
                    distance: Int(distance),
                    frequencyHeart: Int(avgHeartRate)
                )
            }
        }
        healthStore.execute(query)
    }
    
    
}




