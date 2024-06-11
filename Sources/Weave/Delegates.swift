import Foundation

class AllowInsecureRequestDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge) async -> (URLSession.AuthChallengeDisposition, URLCredential?) {
        if let st = challenge.protectionSpace.serverTrust {
            return (URLSession.AuthChallengeDisposition.useCredential, URLCredential(trust: st))
        } else {
            return (URLSession.AuthChallengeDisposition.useCredential, nil)
        }
    }
}
