import Foundation
import WatchConnectivity


struct AActivity {
    var title: String
    var heartFrequency: Int
    var calories: Int
    var timeDuration: Int
}
/// The WCSession delegate on the watch side
class PhoneWCSessionDelegate: NSObject, WCSessionDelegate,ObservableObject {
    
    @Published var activity: Activity?
    
    /// Assigns this delegate to WCSession and starts the session
    func startSession() {
        guard WCSession.isSupported() else { return }
        print("*** Starting WCSession for phone ***")
        let session = WCSession.default
        session.delegate = self
        print("*** Activating phone WCSession ***")
        session.activate()
    }
    
    /// A delegate function called everytime WCSession is activated
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("*** Phone WCSession activation error: \(error) ***")
        } else {
            switch activationState {
            case .activated:
                print("*** WCSession activated for phone ***")
                print(session.isPaired)
            case .notActivated:
                print("*** WCSession failed to activate for phone ***")
            case .inactive:
                print("*** WCSession inactive for phone ***")
            @unknown default:
                print("*** WCSession activation result: Unknown, for phone ***")
            }
        }
    }
    
    /// A delegate function called everytime WCSession recieves an application context update
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("*** WCSession recieved application context on phone ***")
        
    }
    
    /// A delegate function called everytime WCSession becomes inactive
    func sessionDidBecomeInactive(_ session: WCSession) {
        print("*** WCSession became inactive on phone ***")
    }
    
    /// A delegate function called everytime WCSession deactivates
    func sessionDidDeactivate(_ session: WCSession) {
        print("*** WCSession deactivated on phone ***")
    }
    
    func reciveMessageByWatch(_ message: String) {
        print("*** Message recieved by watch: \(message) ***")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        print("Recebe mensagem")
        if let activity = message["activity"] as? Activity {
            DispatchQueue.main.async {
                print("📱 Valor recebido: \(activity)")
                self.activity = activity
                // Aqui você pode atualizar sua UI ou lógica
            }
        }
    }
    
    
}
