import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

class AccountInfoViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var characterCountLabel: UILabel!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
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
        
        usernameTextField.delegate = self
        usernameTextField.autocorrectionType = .no
        if UserDefaults.standard.string(forKey: "username") != nil{
            let usernameInfo = UserDefaults.standard.string(forKey: "username")!
            usernameTextField.text = usernameInfo
        }
        setUpElements()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else{
            return false
        }
        
        let updateText = currentText.replacingCharacters(in: stringRange, with: string)
        characterCountLabel.text = "\(updateText.count)/20"
        
        return updateText.count < 20
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
//    func isPasswordValid(_ password : String) -> Bool {
//        let passwordTest = NSPredicate(format: "SELF MATCHES %@", "^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[#?!@$%^&*-]).{8,}$")
//        return passwordTest.evaluate(with: password)
//    }

    @IBAction func nextButtonTapped(_ sender: Any) {
        //try testing unique username
        errorLabel.isHidden = false
        errorLabel.textColor = .red
        errorLabel.text = ""
        let db = Firestore.firestore()
        guard let username = usernameTextField.text?.lowercased() else { return }
        //check caps and no caps (see search)
        let docRef = db.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
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
                    strongSelf.errorLabel.textColor = .red
                    strongSelf.errorLabel.text = "Username has been taken"
                } else {
                    let whitespace = NSCharacterSet.whitespaces
                    if ((strongSelf.usernameTextField.text!.rangeOfCharacter(from: whitespace)) != nil){
                        print(strongSelf.usernameTextField.text ?? "default value")
                        print("WHITESPACE DETECTED")
                        strongSelf.errorLabel.isHidden = false
                        strongSelf.errorLabel.text = "Username contains whitespaces"
                    }
                    else if strongSelf.usernameTextField.text == ""{
                        strongSelf.errorLabel.isHidden = false
                        strongSelf.errorLabel.text = "Please complete all fields"
                    }
                    else{
                            strongSelf.errorLabel.isHidden = true
                            UserDefaults.standard.set(username, forKey:"username")
                            let controller = strongSelf.storyboard?.instantiateViewController(identifier: "personalInfoViewController") as! PersonalInfoViewController
                            controller.modalTransitionStyle = .crossDissolve
                            controller.modalPresentationStyle = .fullScreen
                            strongSelf.present(controller, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "explained5ViewController") as! Explained5ViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    
}
