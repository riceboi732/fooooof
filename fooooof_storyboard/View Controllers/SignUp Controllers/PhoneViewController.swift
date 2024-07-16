import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

class PhoneViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate{
    @IBOutlet weak var phoneTextField: UITextField!
    @IBOutlet weak var phoneExtTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var country: String?
    
    let countryList = Constants.listOfCountries
    let convertCountryToCode = Constants.countryDictionary
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if phoneTextField.text != "" && phoneExtTextField.text != "" {
            nextButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        }
        
        nextButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
        nextButton.tintColor = UIColor.white
        nextButton.titleLabel!.textColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        
        UserDefaults.standard.removeObject(forKey: "verificationCode")
        UserDefaults.standard.removeObject(forKey: "verification_id")
        createAndSetupPickerView()
        dismissAndClosePickerView()
        backButton.setTitle("", for: .normal)
        nextButton.setTitle("", for: .normal)
        phoneTextField.attributedPlaceholder = NSAttributedString(string: "Phone number", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20)])
        phoneExtTextField.layer.cornerRadius = phoneExtTextField.frame.size.width/2
        phoneExtTextField.layer.masksToBounds = true
        phoneExtTextField.attributedPlaceholder = NSAttributedString(string: "+1", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 20), NSAttributedString.Key.foregroundColor: UIColor.black])
        phoneTextField.keyboardType = .asciiCapableNumberPad
        phoneTextField.becomeFirstResponder()
        
        phoneTextField.layer.cornerRadius = phoneTextField.frame.size.width/2
        phoneTextField.layer.masksToBounds = true
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
    
    @IBAction func nextButtonPressed(_ sender: Any){
        errorLabel.isHidden = false
        errorLabel.textColor = .red
        errorLabel.text = ""
        let db = Firestore.firestore()
        let phone = "+\(phoneExtTextField.text!)\(phoneTextField.text!)"
        //check caps and no caps (see search)
        let docRef = db.collection("users").whereField("phone", isEqualTo: phone).limit(to: 1)
        docRef.getDocuments { [weak self] (querysnapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if error != nil {
                print("Document Error: ", error!)
            }
            else if phone == "+16505551234"{
                strongSelf.errorLabel.isHidden = true
                UserDefaults.standard.set(phone, forKey:"phone")
                //Set a defauly password for all users to avoid issues during user creation
                UserDefaults.standard.set("Testing1!", forKey:"password")
                AuthManager.shared.startAuth(phoneNumber: phone){ [weak self] success in
                    guard success else {return}
                    DispatchQueue.main.async{
                        let controller = self?.storyboard?.instantiateViewController(identifier: "smsCodeViewController") as! SMSCodeViewController
                        controller.modalTransitionStyle = .crossDissolve
                        controller.modalPresentationStyle = .fullScreen
                        self?.present(controller, animated: true, completion: nil)
                    }
                }
            }
            else {
                if let doc = querysnapshot?.documents, !doc.isEmpty {
                    strongSelf.errorLabel.isHidden = false
                    strongSelf.errorLabel.textColor = .red
                    strongSelf.errorLabel.text = "Phone has been taken"
                    print("Not a unique phone.")
                } else {
                    if strongSelf.phoneTextField.text == "" || strongSelf.phoneExtTextField.text == ""{
                        strongSelf.errorLabel.isHidden = false
                        strongSelf.errorLabel.text = "Please complete all fields"
                    }
                    else{
                        strongSelf.errorLabel.isHidden = true
                        UserDefaults.standard.set(phone, forKey:"phone")
                        AuthManager.shared.startAuth(phoneNumber: phone){ [weak self] success in
                            guard success else {return}
                            DispatchQueue.main.async{
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
