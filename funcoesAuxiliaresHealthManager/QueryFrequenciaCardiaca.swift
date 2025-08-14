//
//  QueryFrequenciaCardiaca.swift
//  BeActiv
//
//  Created by Filipi Romão on 14/08/25.
//

import Foundation
import HealthKit

func queryFrequenciaCardiaca(workout: HKWorkout, healthStore: HKHealthStore, completionHandler: @escaping (Double) -> Void){
    
    var somaFrequencia: Double = 0
    
    
    // Verifica se o tipo de dado para frequência cardíaca (heartRate) está disponível no HealthKit
    if let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate) {
        //Filtra a frequencia de batimento atraves do workout, ou seja so buscará a frequencia pelo workout informado
        let hrPredicate = HKQuery.predicateForObjects(from: workout)
        //Realiza a query buscando pelo tipo de dado do batimento, usando o filtro de ser só por treino e é sem limite
        let hrQuery = HKSampleQuery(sampleType: heartRateType, predicate: hrPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            
            //Verifica se hrSamples recebe um array da HKQuantity, que é uma frequencia de BPM, mas durante o treino sao registrados varias BPM, entao precisa receber um array desses BPM
            var mediaFrequencia: Double = 0
            if let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty {
                
                //Percorre todas os valores dos BPM
                for sample in hrSamples {
                    //Variavel que armazena cada BPM, formatando para valor double e pega so as frequencias por minuto
                    let bpm = sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    //Salva na variavel soma todos os bpm
                    somaFrequencia += bpm
                }
                // Calcula a média dividindo pelo total de amostras
                mediaFrequencia = somaFrequencia/Double(hrSamples.count)
                completionHandler(mediaFrequencia)
            }
            
            
            
            
        }
        //Executa a query do BPM
        healthStore.execute(hrQuery)
        
    }
    
    
}
