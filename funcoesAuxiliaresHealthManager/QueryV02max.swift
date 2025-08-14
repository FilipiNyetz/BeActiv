//
//  QueryV02max.swift
//  BeActiv
//
//  Created by Filipi Romão on 14/08/25.
//

import Foundation
import HealthKit

func queryV02max(workout: HKWorkout, healthStore: HKHealthStore) {
    if let v02MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max) {
        let v02MaxPredicate = HKQuery.predicateForObjects(from: workout)
        let v02MaxQuery = HKSampleQuery(sampleType: v02MaxType, predicate: v02MaxPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            
            var v02Max: Double = 0
            
            if let v02MaxSamples = samples as? [HKQuantitySample], !v02MaxSamples.isEmpty {
                let v02MaxValues = v02MaxSamples.map {
                    $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute())) }
                v02Max = v02MaxValues.reduce(0, +) / Double(v02MaxValues.count)
                print("O vo2 max é: \(v02Max)")
            }
            
        }
       healthStore.execute(v02MaxQuery)
        
    }
}
