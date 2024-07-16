//
//  PersonalProfileSingle ViewController.swift
//  fooooof_storyboard
//
//  Created by Jessica Chen on 11/26/22.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class PersonalProfileSingleViewController: UIViewController {
    
    @IBOutlet weak var fieldLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    @IBOutlet weak var updateButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var field = ""
    var value = ""
    let db = Firestore.firestore()
    let selfUid = Auth.auth().currentUser!.uid
    
    @IBOutlet weak var updateBottomConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fieldLabel.text = field
        textField.text = value
        backButton.setTitle("", for: .normal)
        //  Registering for keyboard notification.
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidShow(_:)), name: UIResponder.keyboardDidShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDidHide(_:)), name: UIResponder.keyboardDidHideNotification, object: nil)
        
    }
    
    @IBAction func updateDatabaseValue(_ sender: Any) {
        if field == "Username" {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = ""
            changeUsername()
        } else if field == "School" {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = ""
            changeSchool()
        } else if field == "Class" {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = ""
            changeClass()
        } else if field == "Major" {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = ""
            changeMajor()
        } else if field == "Company" {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = ""
            changeCompany()
        } else if field == "Current position" {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = ""
            changePosition()
        } else {
            print("not username")
        }
    }
    
    func changeUsername() {
        let selfProfile = db.collection("users").document(selfUid)
        guard let username = textField.text?.lowercased() else { return }
        let docRef = db.collection("users").whereField("username", isEqualTo: username).limit(to: 1)
        docRef.getDocuments { [weak self] (querysnapshot, error) in
            guard let strongSelf = self else {
                return
            }
            print("change field 2")
            if error != nil {
                print("Document Error: ", error!)
            } else if username == strongSelf.value {
                strongSelf.errorLabel.isHidden = true
            } else {
                if let doc = querysnapshot?.documents, !doc.isEmpty {
                    strongSelf.errorLabel.isHidden = false
                    strongSelf.errorLabel.textColor = .red
                    strongSelf.errorLabel.text = "Username has been taken"
                } else {
                    if strongSelf.textField.text == ""{
                        strongSelf.errorLabel.isHidden = false
                        strongSelf.errorLabel.textColor = .red
                        strongSelf.errorLabel.text = "Please enter a valid username"
                    } else{
                        strongSelf.errorLabel.isHidden = true
                        strongSelf.value = username
                        strongSelf.errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
                        selfProfile.setData(["username":username], merge: true)
                        let controller = strongSelf.storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
                        controller.modalTransitionStyle = .crossDissolve
                        controller.modalPresentationStyle = .fullScreen
                        strongSelf.present(controller, animated: true, completion: nil)
                    }
                }
            }
        }
    }
    
    func changeSchool() {
        let selfProfile = db.collection("users").document(selfUid)
        guard let school = textField.text else { return }
        if school == value {
            errorLabel.isHidden = true
        } else if textField.text == ""{
                errorLabel.isHidden = false
                errorLabel.textColor = .red
                errorLabel.text = "Please enter a valid name"
        } else{
                errorLabel.isHidden = true
                value = school
                errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
                selfProfile.setData(["college":school], merge: true)
            let controller = self.storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func changeClass() {
        let selfProfile = db.collection("users").document(selfUid)
        guard let classYear = textField.text else { return }
        if classYear == value {
            errorLabel.isHidden = true
        } else if textField.text == ""{
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = "Please enter a valid year"
        } else if !CharacterSet.decimalDigits.isSuperset(of: CharacterSet(charactersIn: textField.text ?? "")) {
            errorLabel.isHidden = false
            errorLabel.textColor = .red
            errorLabel.text = "Please enter only numbers"
        } else {
            errorLabel.isHidden = true
            value = classYear
            errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
            selfProfile.setData(["classYear":classYear], merge: true)
            let controller = self.storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func changeMajor() {
        let selfProfile = db.collection("users").document(selfUid)
        guard let major = textField.text else { return }
        if major == value {
            errorLabel.isHidden = true
        } else if textField.text == ""{
                errorLabel.isHidden = false
                errorLabel.textColor = .red
                errorLabel.text = "Please enter a valid name"
        } else{
                errorLabel.isHidden = true
                value = major
                errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
                selfProfile.setData(["major":major], merge: true)
            let controller = self.storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func changeCompany() {
        let selfProfile = db.collection("users").document(selfUid)
        guard let company = textField.text else { return }
        if company == value {
            errorLabel.isHidden = true
        } else if textField.text == ""{
                errorLabel.isHidden = false
                errorLabel.textColor = .red
                errorLabel.text = "Please enter a valid name"
        } else{
                errorLabel.isHidden = true
                value = company
                errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
                selfProfile.setData(["company":company], merge: true)
            let controller = self.storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    func changePosition() {
        let selfProfile = db.collection("users").document(selfUid)
        guard let position = textField.text else { return }
        if position == value {
            errorLabel.isHidden = true
        } else if textField.text == ""{
                errorLabel.isHidden = false
                errorLabel.textColor = .red
                errorLabel.text = "Please enter a valid name"
        } else{
                errorLabel.isHidden = true
                value = position
                errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
                selfProfile.setData(["position":position], merge: true)
            let controller = self.storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            self.present(controller, animated: true, completion: nil)
        }
    }
    
    /*  UIKeyboardWillShowNotification. */
    @objc internal func keyboardWillShow(_ notification : Notification?) -> Void {
        
        var _kbSize:CGSize!
        
        if let info = notification?.userInfo {
            
            let frameEndUserInfoKey = UIResponder.keyboardFrameEndUserInfoKey
            
            //  Getting UIKeyboardSize.
            if let kbFrame = info[frameEndUserInfoKey] as? CGRect {
                
                let screenSize = UIScreen.main.bounds
                
                //Calculating actual keyboard displayed size, keyboard frame may be different when hardware keyboard is attached (Bug ID: #469) (Bug ID: #381)
                let intersectRect = kbFrame.intersection(screenSize)
                
                if intersectRect.isNull {
                    _kbSize = CGSize(width: screenSize.size.width, height: 0)
                } else {
                    _kbSize = intersectRect.size
                }
                print("Your Keyboard Size \(String(describing: _kbSize.height))")
                
                updateBottomConstraint.constant = _kbSize.height+15
            }
        }
    }
    
    @objc internal func keyboardDidShow(_ notification : Notification?) -> Void {
        
        var _kbSize:CGSize!
        
        if let info = notification?.userInfo {
            
            let frameEndUserInfoKey = UIResponder.keyboardFrameEndUserInfoKey
            
            //  Getting UIKeyboardSize.
            if let kbFrame = info[frameEndUserInfoKey] as? CGRect {
                
                let screenSize = UIScreen.main.bounds
                
                //Calculating actual keyboard displayed size, keyboard frame may be different when hardware keyboard is attached (Bug ID: #469) (Bug ID: #381)
                let intersectRect = kbFrame.intersection(screenSize)
                
                if intersectRect.isNull {
                    _kbSize = CGSize(width: screenSize.size.width, height: 0)
                } else {
                    _kbSize = intersectRect.size
                }
                print("Your Keyboard Size \(String(describing: _kbSize.height))")
                
                updateBottomConstraint.constant = _kbSize.height+15
            }
        }
    }
    
    /*  UIKeyboardWillShowNotification. */
    @objc internal func keyboardDidHide(_ notification : Notification?) -> Void {
        
        updateBottomConstraint.constant = 50
        
    }
}
