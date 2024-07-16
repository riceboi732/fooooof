
import UIKit
import FirebaseAuth
import Firebase
import FirebaseCore
import FirebaseFirestore
import JGProgressHUD

class LoginSMSCodeViewController: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var codeField1: UITextField!
    @IBOutlet weak var codeField2: UITextField!
    @IBOutlet weak var codeField3: UITextField!
    @IBOutlet weak var codeField4: UITextField!
    @IBOutlet weak var codeField5: UITextField!
    @IBOutlet weak var codeField6: UITextField!
    @IBOutlet weak var errorLabel: UILabel!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        backButton.setTitle("", for: .normal)
        nextButton.setTitle("", for: .normal)
        
        
        codeField1.keyboardType = .asciiCapableNumberPad
        codeField2.keyboardType = .asciiCapableNumberPad
        codeField3.keyboardType = .asciiCapableNumberPad
        codeField4.keyboardType = .asciiCapableNumberPad
        codeField5.keyboardType = .asciiCapableNumberPad
        codeField6.keyboardType = .asciiCapableNumberPad
        
        codeField1.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        codeField2.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        codeField3.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        codeField4.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        codeField5.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        codeField6.addTarget(self, action: #selector(textDidChange), for: .editingChanged)
        
        codeField1.layer.cornerRadius = codeField1.frame.size.height/2
        codeField1.layer.masksToBounds = true
        codeField1.layer.borderWidth = 1
        codeField1.layer.borderColor = UIColor.gray.cgColor
        codeField2.layer.cornerRadius = codeField2.frame.size.width/2
        codeField2.layer.masksToBounds = true
        codeField2.layer.borderWidth = 1
        codeField2.layer.borderColor = UIColor.gray.cgColor
        codeField3.layer.cornerRadius = codeField3.frame.size.width/2
        codeField3.layer.masksToBounds = true
        codeField3.layer.borderWidth = 1
        codeField3.layer.borderColor = UIColor.gray.cgColor
        codeField4.layer.cornerRadius = codeField4.frame.size.width/2
        codeField4.layer.masksToBounds = true
        codeField4.layer.borderWidth = 1
        codeField4.layer.borderColor = UIColor.gray.cgColor
        codeField5.layer.cornerRadius = codeField5.frame.size.width/2
        codeField5.layer.masksToBounds = true
        codeField5.layer.borderWidth = 1
        codeField5.layer.borderColor = UIColor.gray.cgColor
        codeField6.layer.cornerRadius = codeField6.frame.size.width/2
        codeField6.layer.masksToBounds = true
        codeField6.layer.borderWidth = 1
        codeField6.layer.borderColor = UIColor.gray.cgColor
    }
    
    @objc func textDidChange(textField: UITextField){
        let text = textField.text
        if text?.count == 1{
            switch textField{
            case codeField1:
                codeField2.becomeFirstResponder()
            case codeField2:
                codeField3.becomeFirstResponder()
            case codeField3:
                codeField4.becomeFirstResponder()
            case codeField4:
                codeField5.becomeFirstResponder()
            case codeField5:
                codeField6.becomeFirstResponder()
            case codeField6:
                codeField6.resignFirstResponder()
            default:
                break
            }
        }
        if text?.count == 0{
            switch textField{
            case codeField1:
                codeField1.becomeFirstResponder()
            case codeField2:
                codeField1.becomeFirstResponder()
            case codeField3:
                codeField2.becomeFirstResponder()
            case codeField4:
                codeField3.becomeFirstResponder()
            case codeField5:
                codeField4.becomeFirstResponder()
            case codeField6:
                codeField5.becomeFirstResponder()
            default:
                break
            }
        }
    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "loginPhoneViewController") as! LoginPhoneViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any){
        if codeField1.text == "" || codeField2.text == "" || codeField3.text == "" || codeField4.text == "" || codeField5.text == "" || codeField6.text == ""{
            errorLabel.isHidden = false
            errorLabel.text = "Please complete text field"
        }
        else{
            spinner.show(in: view)
            errorLabel.isHidden = true
            errorLabel.textColor = .red
            errorLabel.text = ""

            let verificationID = UserDefaults.standard.string(forKey: "verificationID")
            let db = Firestore.firestore()
            let phone = UserDefaults.standard.string(forKey: "phone")
            let docRef = db.collection("users").whereField("phone", isEqualTo: phone!).limit(to: 1)
            
            if verificationID != nil{
                let verificationCode = codeField1.text! + codeField2.text! + codeField3.text! + codeField4.text! + codeField5.text! + codeField6.text!
                print(verificationCode)
                let credential = PhoneAuthProvider.provider().credential(withVerificationID: verificationID!, verificationCode: verificationCode)
                Auth.auth().settings?.isAppVerificationDisabledForTesting = false
                Auth.auth().signIn(with: credential)
                {(authData, error) in
                    if error != nil{
                        DispatchQueue.main.async{
                            self.spinner.dismiss()
                        }
                        print(error.debugDescription)
                        self.errorLabel.isHidden = false
                        self.errorLabel.text = "Incorrect verification code."
                        return
                    }
                    else{
                        docRef.getDocuments{ [weak self] (querysnapshot, error) in
                            guard let strongSelf = self else {
                                return
                            }
                            if error != nil {
                                print("Document Error: ", error!)
                            }
                            else {
                                if let doc = querysnapshot?.documents, !doc.isEmpty {
                                    DispatchQueue.main.async{
                                        strongSelf.spinner.dismiss()
                                    }
                                    print("Authentication success" + (authData?.user.phoneNumber! ?? "No Phone Number"))
                                    UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                                    let userUid = Auth.auth().currentUser!.uid
                                    Firestore.firestore().collection("users").document(userUid).getDocument { (snapshot, error) in
                                        if let dictionary = snapshot?.data() as? [String: AnyObject]{
                                            UserDefaults.standard.set(dictionary["firstName"] as! String, forKey:"firstname")
                                            UserDefaults.standard.set(dictionary["lastName"] as! String, forKey:"lastname")
                                        }
                                    }
                                    
                                    let controller = strongSelf.storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
                                    strongSelf.view.window?.rootViewController = controller
                                    strongSelf.view.window?.makeKeyAndVisible()
                                }
                                else {
//                                    DispatchQueue.main.async{
//                                        strongSelf.spinner.dismiss()
//                                    }
                                    strongSelf.errorLabel.isHidden = true
                                    UserDefaults.standard.set(phone, forKey:"phone")
                                    let controller = strongSelf.storyboard?.instantiateViewController(identifier: "signUpViewController") as! SignUpViewController
                                    controller.modalTransitionStyle = .crossDissolve
                                    controller.modalPresentationStyle = .fullScreen
                                    strongSelf.present(controller, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                }
            }
            else{
                print("error in getting verificaiton ID")
            }
        }
    }
}
