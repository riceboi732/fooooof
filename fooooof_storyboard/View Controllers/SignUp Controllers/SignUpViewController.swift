import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

class SignUpViewController: UIViewController {
    
    @IBOutlet var emailTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
        nextButton.tintColor = UIColor.white
        nextButton.titleLabel!.textColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        
        if UserDefaults.standard.string(forKey: "email") != nil{
            let emailInfo = UserDefaults.standard.string(forKey: "email")!
            emailTextField.text = emailInfo
        }
        nextButton.setTitle("", for: .normal)
        emailTextField.becomeFirstResponder()
        setUpElements()
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    func isEmailValid(_ email : String) -> Bool {
        let emailTest = NSPredicate(format: "SELF MATCHES %@", "(?:[a-zA-Z0-9!#$%\\&‘*+/=?\\^_`{|}~-]+(?:\\.[a-zA-Z0-9!#$%\\&'*+/=?\\^_`{|}"
            + "~-]+)*|\"(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21\\x23-\\x5b\\x5d-\\"
            + "x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])*\")@(?:(?:[a-z0-9](?:[a-"
            + "z0-9-]*[a-z0-9])?\\.)+[a-z0-9](?:[a-z0-9-]*[a-z0-9])?|\\[(?:(?:25[0-5"
            + "]|2[0-4][0-9]|[01]?[0-9][0-9]?)\\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-"
            + "9][0-9]?|[a-z0-9-]*[a-z0-9]:(?:[\\x01-\\x08\\x0b\\x0c\\x0e-\\x1f\\x21"
            + "-\\x5a\\x53-\\x7f]|\\\\[\\x01-\\x09\\x0b\\x0c\\x0e-\\x7f])+)\\])")
        return emailTest.evaluate(with: email)
    }
    
    //Implement valid phone number check later
    func validateFields(){
        return
    }
    @IBAction func nextButtonTapped(_ sender: Any) {
        //try testing unique username
        errorLabel.isHidden = false
        errorLabel.text = ""
        let db = Firestore.firestore()
        guard let email = emailTextField.text else { return }
        //check caps and no caps (see search)
        let docRef = db.collection("users").whereField("email", isEqualTo: email).limit(to: 1)
        docRef.getDocuments { [weak self] (querysnapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if error != nil {
                print("Document Error: ", error!)
            }
            else {
                if let doc = querysnapshot?.documents, !doc.isEmpty {
                    strongSelf.errorLabel.isHidden = false
                    strongSelf.errorLabel.text = "Email has been taken"
                    print("Not a unique email.")
                } else {
                    if strongSelf.emailTextField.text == "" {
                        strongSelf.errorLabel.isHidden = false
                        strongSelf.errorLabel.text = "Please complete all fields"
                    }
                        else{
                            if !strongSelf.isEmailValid(strongSelf.emailTextField.text!){
                                strongSelf.errorLabel.isHidden = false
                                strongSelf.errorLabel.text = "Please enter a valid email: (Ex. janedoe@email.com)"
                            }
                            else{
                                strongSelf.errorLabel.isHidden = true
                                UserDefaults.standard.set(strongSelf.emailTextField.text, forKey:"email")
                                let controller = strongSelf.storyboard?.instantiateViewController(identifier: "explain1ViewController") as! Explain1ViewController
                                controller.modalTransitionStyle = .crossDissolve
                                controller.modalPresentationStyle = .fullScreen
                                strongSelf.present(controller, animated: true, completion: nil)
                            }
                    }
                }
            }
        }
    }
}
