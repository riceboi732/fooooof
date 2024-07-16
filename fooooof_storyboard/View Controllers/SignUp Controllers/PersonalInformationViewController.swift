import UIKit

class PersonalInfoViewController: UIViewController, UITextFieldDelegate {
    @IBOutlet weak var firstnameTextField: UITextField!
    @IBOutlet weak var firstnameCharacterCountLabel: UILabel!
    @IBOutlet weak var lastnameCharacterCountLabel: UILabel!
    @IBOutlet weak var lastnameTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
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
        
        firstnameTextField.delegate = self
        lastnameTextField.delegate = self
        
        firstnameTextField.autocorrectionType = .no
        lastnameTextField.autocorrectionType = .no
        
        if UserDefaults.standard.string(forKey: "firstname") != nil && UserDefaults.standard.string(forKey: "lastname") != nil{
            let firstnameInfo = UserDefaults.standard.string(forKey: "firstname")!
            firstnameTextField.text = firstnameInfo
            let lastnameInfo = UserDefaults.standard.string(forKey: "lastname")!
            lastnameTextField.text = lastnameInfo
        }
        setUpElements()
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        let currentText = textField.text ?? ""
        guard let stringRange = Range(range, in: currentText) else{
            return false
        }
        
        let updateText = currentText.replacingCharacters(in: stringRange, with: string)
        
        if textField == firstnameTextField{
            firstnameCharacterCountLabel.text = "\(updateText.count)/20"
            return updateText.count < 20
        }
        else if textField == lastnameTextField{
            lastnameCharacterCountLabel.text = "\(updateText.count)/20"
            return updateText.count < 20
        }
        
        return updateText.count < 20
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    @objc func dismissAction(){
        view.endEditing(true)
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        let whitespace = NSCharacterSet.whitespaces
        if (firstnameTextField.text!.rangeOfCharacter(from: whitespace) != nil || lastnameTextField.text!.rangeOfCharacter(from: whitespace) != nil){
            print("WHITESPACE DETECTED")
            errorLabel.isHidden = false
            errorLabel.text = " Name contains whitespaces"
        }
        else if firstnameTextField.text == "" || lastnameTextField.text == ""{
            errorLabel.isHidden = false
            errorLabel.text = "Please enter information in all fields"
        }
        else{
            errorLabel.isHidden = true
            UserDefaults.standard.set(firstnameTextField.text, forKey:"firstname")
            UserDefaults.standard.set(lastnameTextField.text, forKey:"lastname")
            let controller = storyboard?.instantiateViewController(identifier: "genderViewController") as! GenderViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "accountInfoViewController") as! AccountInfoViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
}

