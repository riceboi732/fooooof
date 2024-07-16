import UIKit
import FirebaseAuth
import Firebase
import FirebaseCore
import FirebaseFirestore
import JGProgressHUD

class LoginPhoneViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource{
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var phoneExtTextField: UITextField!
    @IBOutlet weak var SMSVerificationTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var country: String?
    
    let countryList = Constants.listOfCountries
    let convertCountryToCode = Constants.countryDictionary
    private let spinner = JGProgressHUD(style: .dark)
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        nextButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
//        nextButton.tintColor = UIColor.white
//        nextButton.imageView!.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
//        nextButton.layer.borderWidth = 1
//        nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        
        self.phoneTextField.delegate = self
        
        SMSVerificationTextField.isHidden = true
        createAndSetupPickerView()
        dismissAndClosePickerView()
        backButton.setTitle("", for: .normal)
        nextButton.setTitle("", for: .normal)
        phoneTextField.attributedPlaceholder = NSAttributedString(string: "Phone number", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)])
        phoneExtTextField.attributedPlaceholder = NSAttributedString(string: "+1", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.black])
        phoneTextField.keyboardType = .asciiCapableNumberPad
        phoneTextField.becomeFirstResponder()
    }
    
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if textField.text!.count == 10{
//            nextButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
//            nextButton.imageView?.tintColor = UIColor.white
            nextButton.isUserInteractionEnabled = true
            print("BUTTON IS ENABLED")
        }
        else{
//            nextButton.tintColor = UIColor.white
//            nextButton.titleLabel?.textColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            nextButton.isUserInteractionEnabled = false
            print("BUTTON IS DISABLED")
        }
    }
    
    
    func createAndSetupPickerView(){
        let pickerView = UIPickerView()
        pickerView.delegate = self
        pickerView.dataSource = self
        phoneExtTextField.inputView = pickerView
    }
    
    func dismissAndClosePickerView(){
        let toolbar = UIToolbar()
        toolbar.sizeToFit()
        
        let button = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(dismissAction))
        toolbar.setItems([button], animated: true)
        toolbar.isUserInteractionEnabled = true
        phoneExtTextField.inputAccessoryView = toolbar
    }
        
    @objc func dismissAction(){
        view.endEditing(true)
    }
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int{
        return countryList.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String?{
        return countryList[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int){
        country = countryList[row]
        phoneExtTextField.text = convertCountryToCode[country!]
    }
    
    @IBAction func backButtonPressed(_ sender: Any){
        let controller = storyboard?.instantiateViewController(identifier: "ViewController") as! ViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    var verification_id : String? = nil
    
    @IBAction func nextButtonPressed(_ sender: Any){
        errorLabel.isHidden = false
        errorLabel.textColor = .red
        errorLabel.text = ""
        let db = Firestore.firestore()
        let phone = "+\(phoneExtTextField.text!)\(phoneTextField.text!)"
        let docRef = db.collection("users").whereField("phone", isEqualTo: phone).limit(to: 1)
        if phoneTextField.text == "" || phoneExtTextField.text == ""{
            errorLabel.isHidden = false
            errorLabel.text = "Please complete all fields"
        }
        else{
            spinner.show(in: view)
            docRef.getDocuments{ [self] (querysnapshot, error) in
                if error != nil {
                    print("Document Error: ", error!)
                }
                else {
                    
                    //phone number if already being used
                    if let doc = querysnapshot?.documents, !doc.isEmpty {
                        Auth.auth().settings?.isAppVerificationDisabledForTesting = false
                        PhoneAuthProvider.provider().verifyPhoneNumber(phone, uiDelegate: nil){ [weak self] verificationID, error in
                            guard let strongSelf = self else {
                                return
                            }
                            if(error != nil){
                                print(error.debugDescription)
                            }
                            else{
                                strongSelf.verification_id = verificationID
                                UserDefaults.standard.set(verificationID, forKey: "verificationID")
                                UserDefaults.standard.set(phone, forKey: "phone")
                                DispatchQueue.main.async{
                                    strongSelf.spinner.dismiss()
                                    let controller = strongSelf.storyboard?.instantiateViewController(withIdentifier: "loginSMSCodeViewController") as! LoginSMSCodeViewController
                                    controller.modalTransitionStyle = .crossDissolve
                                    controller.modalPresentationStyle = .fullScreen
                                    strongSelf.present(controller, animated: true, completion: nil)
                                }
                            }
                        }
                    }
                    
                    //new phone number
                    else {
                        errorLabel.isHidden = true
                        UserDefaults.standard.set(phone, forKey:"phone")
                        AuthManager.shared.startAuth(phoneNumber: phone){ [weak self] success in
                            guard success else {return}
                            DispatchQueue.main.async{
                                self?.spinner.dismiss()
                                let controller = self?.storyboard?.instantiateViewController(identifier: "smsCodeViewController") as! SMSCodeViewController
                                controller.modalTransitionStyle = .crossDissolve
                                controller.modalPresentationStyle = .fullScreen
                                self?.present(controller, animated: true, completion: nil)
                            }
                        }
                    }
                }
            }
        }
    }
}

extension LoginPhoneViewController: UITextFieldDelegate{
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool{
        let newString = NSString(string: textField.text!).replacingCharacters(in: range, with: string)
        if textField == phoneTextField{
            let component = newString.components(separatedBy: NSCharacterSet.decimalDigits.inverted)
            let decimalString = component.joined(separator: "") as NSString
            let length = decimalString.length
            
            if length > 0{
                let newLength = (textField.text! as NSString).length + (string as NSString).length - range.length as Int
                
                return newLength > 10 ? false : true
            }
        }
        return true
    }
}
