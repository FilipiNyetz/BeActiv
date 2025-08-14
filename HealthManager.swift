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
    
    //Instancia a classe que controla do DB do healthKit, criando o objeto capaz de acessar e gerenciar os dados no healthKit
    let healthStore = HKHealthStore()
    
    //Variavel que aramazena um array de workouts e pode ser acessada pela view
    @Published var workouts: [Workout] = []
    @Published var mediaBatimentosCardiacos: Double = 0.0
    
    init(){
        //Inicia a classe manager declarando quais serão as variaveis e os tipos de dados solicitados ao HealthKit
        let steps = HKQuantityType(.stepCount)
        let calories = HKQuantityType(.activeEnergyBurned)
        let workouts = HKObjectType.workoutType()
        let hearthRate = HKQuantityType(.heartRate)
        let distance = HKQuantityType(.distanceWalkingRunning)
        //Seta um array com todos os valores que precisam ser solicitados para permissao do usuario
        let healthTypes:Set = [steps, calories, workouts, hearthRate, distance]
        
        
        Task{
            do{
                //Realiza um pedido para o usuario permitir compartilhar os dados 
                try await healthStore.requestAuthorization(toShare: healthTypes, read: healthTypes)
                
            } catch {
                print("Error fetching data")
            }
        }
    }
    
    //Funcao principal para buscar os dados de treino diarios
    func fetchWorkout(){
//        print(Date.startOfToday)
//        print(Date.endOfToday)
        
        //Remove todos os workouts ja buscados, porque todas as vezes que chamar a funcao ela vai buscar todos os dados, entao apagar tudo evita ficar acumulando
        DispatchQueue.main.async {
            self.workouts.removeAll()
        }
        //Declara uma variavel workout conformando com o tipo de dado do HealthKit que reprensenta um treino
        let workout = HKObjectType.workoutType()
        
        // Tipo de dado do HealthKit que representa a frequência cardíaca
        let heartQuantityType = HKObjectType.quantityType(
            forIdentifier: .heartRate
        )!
        
        //Parametro de recorte de tempo para fazer a query com base nesse parametro(filtra treinos so do comeco ate o final do dia)
        let timePredicate = HKQuery.predicateForSamples(
            withStart: Date.startOfToday,
            end: Date.endOfToday
        )
        
        //Parametro da query baseado no tipo de treino(filtra so treinos de corrida)
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .running)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, workoutPredicate])
        
        //Realiza uma query simples, buscando o tipo de treino, seguindo os parametros de busca predicate(filtros) e limitando a 25 respostas
        let query = HKSampleQuery(sampleType: workout, predicate: predicate, limit: 25, sortDescriptors: nil){_, sample, error in
            
            //Tenta converter o resultado(sample) para um array de HKWorkout
            //Desempacota um opcional de ssample, se existir e for do tipo de dado HKWorkout e o erro for igual a nil vai seguir a funcao, se nao vai travar
            guard let workouts = sample as? [HKWorkout] , error == nil else{
                print("error fetching todays workout data")
                return
            }
            //Inicia a variavel com 0
            var count: Int = 0
            //percorre todos os workouts, pegando valores de cada workout(item dentro do array)
            for workout in workouts {
                print("Workout tipo: \(workout.workoutActivityType)")
                //Tempo de duração é o numero inteiro do tempo/60
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
                
                //Para manipular a formatacao da distancia para metros utiliza isso
                //Se existir distance (workout.totalDistance) pega o valor de double e obtém a unidade em metros
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
        
        // Predicados para semana e tipo de treino(filtros)
        let timePredicate = HKQuery.predicateForSamples(withStart: .startOfWeek, end: .endOfWeek)
        let workoutPredicate = HKQuery.predicateForWorkouts(with: .soccer)
        let predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [timePredicate, workoutPredicate])
        
        // Query principal de workouts, baseando se nos filtros
        let query = HKSampleQuery(sampleType: workoutType, predicate: predicate, limit: 10, sortDescriptors: nil) { _, samples, error in
            
            //Verifica se recebeu de fato um array de HKWorkout e desempacota para garantir que existe e é do tipo certo. Verifica tambem se nao existe erros
            guard let workouts = samples as? [HKWorkout], error == nil else {
                print("Erro ao buscar workouts da semana")
                return
            }
            
            //percorre todos os workouts e pega um por um
            for workout in workouts {
                let durationMinutes = Int(workout.duration) / 60
                
                // Calorias
                let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
                
                // Distância
                let distance = workout.totalDistance?.doubleValue(for: .meter()) ?? 0
              
//                //Declara a variavel para armazenar a media dos BPM duante todo o workout, inicia com 0
                //Chama a funcao para receber o retorno dela
//                let mediaHeartRate: Double = queryFrequenciaCardiaca(workout: workout, healthStore: self.healthStore, completionHandler: mediaFrequencia)
                
                
                
                queryFrequenciaCardiaca(workout: workout, healthStore: self.healthStore){mediaHeartRate in
                    print("A frequência média é: \(mediaHeartRate)")
                    let workoutSummary = Workout(
                        id: UUID(),
                        idWorkoutType: Int(workout.workoutActivityType.rawValue),
                        duration: durationMinutes,
                        calories: Int(calories),
                        distance: Int(distance),
                        frequencyHeart: mediaHeartRate
                    )
                    DispatchQueue.main.async {
                        self.workouts.append(workoutSummary)
                    }
                   
                }
                
                
                //Declara o sumário do treino, que é uma Struct do tipo Workout, então possui um id, um idWorkoutType, uma duracao, calorias, distancia e frequencyHeart. Dessa forma passa todos os dados necessários para conformar com o Workout
                
                
                
            }
        }
        healthStore.execute(query)
    }
    
    
}




