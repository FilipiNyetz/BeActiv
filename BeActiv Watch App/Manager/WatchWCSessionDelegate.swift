import Foundation
import WatchConnectivity

class WatchWCSessionDelegate: NSObject, WCSessionDelegate, ObservableObject {
    
    @Published var sessionActivated = false
    
    func startSession() {
        guard WCSession.isSupported() else { return }
        print("*** Starting WCSession for Watch ***")
        let session = WCSession.default
        session.delegate = self
        print("*** Activating watch WCSession ***")
        session.activate()
    }
    
    func sendMessage(message: [String: Any],
                     replyHandler: (([String: Any]) -> Void)? = nil,
                     errorHandler: ((Error) -> Void)? = nil) {
        guard WCSession.default.isReachable else {
            print("⚠️ iPhone is not reachable from Watch")
            return
        }
        WCSession.default.sendMessage(message, replyHandler: replyHandler, errorHandler: errorHandler)
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("*** Activation error: \(error.localizedDescription) ***")
        } else {
            print("*** WCSession activated with state: \(activationState.rawValue) ***")
            DispatchQueue.main.async {
                self.sessionActivated = true
            }
        }
    }

    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        print("*** Received application context: \(applicationContext) ***")
    }
}
