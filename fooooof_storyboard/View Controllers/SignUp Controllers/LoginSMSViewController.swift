import UIKit

class LoginSMSCodeViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var codeField: UITextField!
    @IBOutlet weak var errorLabel: UILabel!
    
    //    private let codeField: UITextField = {
    //        let field = UITextField()
    //        field.backgroundColor = .secondarySystemBackground
    //        field.placeholder = "Enter your verification code"
    //        field.returnKeyType = .continue
    //        field.textAlignment = .center
    //        return field
    //    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        backButton.setTitle("", for: .normal)
        nextButton.setTitle("", for: .normal)
        codeField.keyboardType = .asciiCapableNumberPad
        codeField.becomeFirstResponder()
    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "phoneViewController") as! PhoneViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(_ sender: Any){
        self.errorLabel.isHidden = true
        self.errorLabel.textColor = .red
        self.errorLabel.text = ""
        
        if self.codeField.text == "" {
            self.errorLabel.isHidden = false
            self.errorLabel.text = "Please complete text field"
        }
        else{
            let code = codeField.text!
            AuthManager.shared.verifyCode(smsCode: code){ [weak self] success in
                guard success else {
                    self?.errorLabel.isHidden = false
                    self?.errorLabel.text = "Incorrect verification code."
                    return
                }
                DispatchQueue.main.async{
                    let controller = self?.storyboard?.instantiateViewController(withIdentifier: "signUpViewController") as! SignUpViewController
                    controller.modalTransitionStyle = .crossDissolve
                    controller.modalPresentationStyle = .fullScreen
                    self?.present(controller, animated: true, completion: nil)
                }
            }
        }
        
    }
    
    
    
    //    func textFieldShouldReturn(_ textField: UITextField) -> Bool{
    //        textField.resignFirstResponder()
    //
    //        if let text = textField.text, !text.isEmpty{
    //            let code = text
    //            AuthManager.shared.verifyCode(smsCode: code){ [weak self] success in
    //                guard success else {return}
    //                DispatchQueue.main.async{
    //                    let storyBoard : UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
    //                    let controller = storyBoard.instantiateViewController(withIdentifier: "signUpViewController") as! SignUpViewController
    //                    controller.modalPresentationStyle = .fullScreen
    //                    self?.present(controller, animated: true, completion: nil)
    //                }
    //            }
    //        }
    //
    //        return true
    //    }
    
}
