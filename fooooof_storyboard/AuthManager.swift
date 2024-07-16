import Foundation
import FirebaseAuth

class AuthManager{
    static let shared = AuthManager()
    
    private let auth = Auth.auth()
    
    private var verificationId: String?
    
    public func startAuth(phoneNumber: String, completion: @escaping (Bool) -> Void){
        PhoneAuthProvider.provider().verifyPhoneNumber(phoneNumber, uiDelegate: nil){ [weak self] verificationId, error in
            guard let verificationId = verificationId, error == nil else{
                completion(false)
                return
            }
            self?.verificationId = verificationId
            print("verification id: " + verificationId)
            UserDefaults.standard.set(verificationId, forKey: "verification_id")
            completion(true)
        }
    }
    
    public func verifyCode(smsCode: String  , completion: @escaping (Bool) -> Void){
        guard let verificationId = verificationId else {
            completion(false)
            return
        }
        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationId, verificationCode: smsCode)
        auth.signIn(with: credential){result, error in
            guard result != nil, error == nil else{
                completion(false)
                return
            }
            print("smscode" + smsCode)
            UserDefaults.standard.set(smsCode, forKey: "verificationCode")
            completion(true)
        }

    }
}
