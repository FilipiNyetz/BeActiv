//
//  WorkoutManager.swift
//  BeActiv Watch App
//
//  Created by Filipi Romão on 11/08/25.
//

import Foundation
import HealthKit
//HealthKit é a biblioteca que vai permitir monitorar dados atraves do workout, vai permitir criar uma sessão de treino e vai salvar os dados no app fitness

class WorkoutManager: NSObject, ObservableObject{
    
    func formatTime(_ interval: TimeInterval) -> String {
        let seconds = Int(interval) % 60
        let minutes = (Int(interval) / 60) % 60
        let hours = Int(interval) / 3600
        if hours > 0 {
            return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%02d:%02d", minutes, seconds)
        }
    }
    
    //Isso sereve para formatar o tempo quando é exibido na tela timerView
    
    
    //    var workout = HKWorkoutActivityType.other
    //    //Utiliza um valor padrao do HealthKit para definir qual sera o tipo da atividade que o usuario ira realizar
    //
    //    let healthStore = HKHealthStore()// Instancia o DB que ira armazenar os dados do treino
    //
    //    var session: HKWorkoutSession?//Representa a sessão de treino, o estado dela(ativa, pausada...)
    //    var builder: HKLiveWorkoutBuilder?//Responsável por coletar os dados em tempo real
    
    
    func requestAuthorization(){
        // função para solicitar ao usuario os dados dele que serão monitorado
        //HKQuantittyType é uma classe do healthKit para indicar quais valores quantitativos serão observados e monitorados
        let steps = HKQuantityType(.stepCount)
        let calories = HKQuantityType(.activeEnergyBurned)
        let workouts = HKObjectType.workoutType()
        let hearthRate = HKQuantityType(.heartRate)
        let distance = HKQuantityType(.distanceWalkingRunning)
        
        let healthTypes:Set = [steps, calories, workouts, hearthRate, distance]
        //Seta quais valores serão lidos e compartilhados
        
        Task{
            do{
                try await healthStore.requestAuthorization(toShare: healthTypes, read: healthTypes)
                //Solicita permissão da biblioteca para ler e compartilhar os dados do saúde
                
            } catch {
                print("Error fetching data")
            }
        }
    }
    
    //Variaveis q podem ser acessadas na UI para caso seja realizada alguma manipulacao da sessão ou seja necessário visualizar o estado dela
    @Published var isActive: Bool = false
    @Published var elapsedTime: TimeInterval = 0
    
    private var timer: Timer?
    private var startDate: Date?//Recebe o momento inicial do treino
    
    //Função para começar treino
    //    func startWorkout() {
    //        print("Chamou na manager: vai iniciar")
    //        //Cria configuração com base na instancia da classe HKWorkoutConfiguration()
    //        let configuration = HKWorkoutConfiguration()
    //        //Define valores para configurar o objeto criado pela classe HKWorkoutConfiguration, ou seja define configuracoes do treino
    //        configuration.activityType = workout
    //        configuration.locationType = .outdoor
    //
    //
    //        isActive = true//estado do treino
    //        startDate = Date()//Momento inicial do treino
    //        elapsedTime = 0//tempo decorrido
    //
    //        do {
    //            //Inicia a sessão do treino e o builder para monitorar os dados em live
    //            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
    //            builder = session?.associatedWorkoutBuilder()
    //        } catch {
    //            print("Erro criando sessão de treino: \(error.localizedDescription)")
    //            return
    //        }
    //
    //        //Configura como os dados do builder serão monitorados, se ele existir, informa para ele a fonte dos dados DataSource
    //        builder?.dataSource = HKLiveWorkoutDataSource(
    //            healthStore: healthStore,
    //            workoutConfiguration: configuration
    //        )
    //
    //        //Momento em que a sessão é iniciada
    //        let startDate = Date()
    //        session?.startActivity(with: startDate)//Inicia a sessao com o momento inicial do treino
    //        //Inicia o builder no momento inicial do treino e começa a monitorar e observar os dados do treino que foram definidos como parametro de monitramento da sessão
    //        builder?.beginCollection(withStart: startDate) { success, error in
    //            if let error = error {
    //                print("Erro iniciando coleta: \(error.localizedDescription)")
    //
    //            } else {
    //                print("Coleta iniciada com sucesso.")
    //            }
    //        }
    //
    //        startTimer()//Chama a func que comeca o timer
    //    }
    
    
    let healthStore = HKHealthStore()
    var session: HKWorkoutSession?
    var builder: HKLiveWorkoutBuilder?
    
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .outdoor
        
        do{
            session = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = session?.associatedWorkoutBuilder()
            
        }catch{
            return
        }
        
        builder?.dataSource = HKLiveWorkoutDataSource(
            healthStore: healthStore, workoutConfiguration: configuration
        )
        
        session?.delegate = self
        builder?.delegate = self
        
        
        let startDate = Date()
        session?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            
        }
    }
    
    private func startTimer() {
        // Se já existir um timer rodando, invalidamos ele para evitar timers duplicados
        timer?.invalidate()
        
        // Criamos um novo timer que dispara a cada 1 segundo, repetidamente
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            // Dentro do bloco executado a cada segundo:
            
            // Verificamos se a data de início do treino está definida (não é nil)
            if let start = self.startDate {
                // Calculamos o tempo decorrido desde o início do treino
                self.elapsedTime = Date().timeIntervalSince(start)
                // elapsedTime é atualizado com o intervalo (segundos) entre agora e o início
            }
        }
    }
    
    
    //
    //    @Published var running = false
    
    func pause(){
        session?.pause()
        print("Chamou na manager: vai pausar")
    }
    
    func resume(){
        session?.resume()
    }
    
    //    func togglePause(){
    //        if running == true{
    //            pause()
    //        }else{
    //            resume()
    //        }
    //    }
    
    func endWorkout() {
        //Verifica se jhá algum builder(monitoramento ao vivo)
        guard let builder = builder else {
            print("⚠️ Nenhum workout builder ativo para encerrar")
            return
        }
        
        print("Chamou na manager: vai terminar")
        
        // 1. Encerrar a sessão
        session?.end()
        
        // 2. Encerrar a coleta de dados ao vivo
        builder.endCollection(withEnd: Date()) { success, error in
            if let error = error {
                print("Erro ao encerrar coleta: \(error.localizedDescription)")
                return
            }
            
            // 3. Finalizar e salvar o treino no HealthKit
            builder.finishWorkout { workout, error in
                if let error = error {
                    print("Erro ao finalizar treino: \(error.localizedDescription)")
                    return
                }
                
                print("🏁 Treino finalizado e salvo:", workout ?? "Sem dados")
            }
        }
        
        // 4. Atualizar estados locais
        isActive = false
        //        running = false
        timer?.invalidate()
        timer = nil
    }
    
    @Published var averageHeartRate: Double = 0
    @Published var heartRate: Double = 0
    @Published var activeEnergy: Double = 0
    @Published var distance: Double = 0
    @Published var workout: HKWorkout?
    @Published var running = false
    
    func updateForStatistics(_ statistics: HKStatistics?){
        guard let statistics = statistics else { return }
        
        DispatchQueue.main.async {
            switch statistics.quantityType {
            case HKQuantityType.quantityType(forIdentifier: .heartRate):
                let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                self.heartRate = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                self.averageHeartRate = statistics.averageQuantity()?.doubleValue(for: heartRateUnit) ?? 0
            case HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned):
                let energyUnit = HKUnit.kilocalorie()
                self.activeEnergy = statistics.sumQuantity()?.doubleValue(for: energyUnit) ?? 0
                
            case HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning), HKQuantityType.quantityType(forIdentifier: .distanceCycling):
                let meterUnit = HKUnit.meter()
                self.distance = statistics.sumQuantity()?.doubleValue(for: meterUnit) ?? 0
            default :
                return
            }
        }
    }
}




extension WorkoutManager: HKWorkoutSessionDelegate {
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        DispatchQueue.main.async {
            self.running = toState == .running
        }
        
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout{ (workout, error) in
                    DispatchQueue.main.async {
                        self.workout = workout
                    }
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed: \(error.localizedDescription)")
    }
    
}

extension WorkoutManager: HKLiveWorkoutBuilderDelegate {
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            guard let quantityType = type as? HKQuantityType else { return }
            
            let statistics = workoutBuilder.statistics(for: quantityType)
            
            updateForStatistics(statistics)
        }
    }
}
