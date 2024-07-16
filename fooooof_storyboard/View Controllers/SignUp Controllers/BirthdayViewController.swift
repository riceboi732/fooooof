//
//  BirthdayViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 9/14/22.
//

import UIKit

class BirthdayViewController: UIViewController, UITextFieldDelegate{
    
    @IBOutlet weak var dayTextField: UITextField!
    @IBOutlet weak var monthTextField: UITextField!
    @IBOutlet weak var yearTextField: UITextField!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    override func viewDidLoad() {
        dayTextField.delegate = self
        monthTextField.delegate = self
        yearTextField.delegate = self
        dayTextField.tag = 2
        monthTextField.tag = 1
        yearTextField.tag = 3
        
        dayTextField.keyboardType = .asciiCapableNumberPad
        monthTextField.keyboardType = .asciiCapableNumberPad
        yearTextField.keyboardType = .asciiCapableNumberPad
        
        super.viewDidLoad()
        
        nextButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
        nextButton.tintColor = UIColor.white
        nextButton.titleLabel!.textColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        
        dayTextField.keyboardType = .asciiCapableNumberPad
        monthTextField.keyboardType = .asciiCapableNumberPad
        yearTextField.keyboardType = .asciiCapableNumberPad
        
        
        if UserDefaults.standard.string(forKey: "birthday") != nil{
            let birthdayDay = UserDefaults.standard.string(forKey: "birthdayDay")!
            dayTextField.text = birthdayDay
            let birthdayMonth = UserDefaults.standard.string(forKey: "birthdayMonth")!
            monthTextField.text = birthdayMonth
            let birthdayYear = UserDefaults.standard.string(forKey: "birthdayYear")!
            yearTextField.text = birthdayYear
        }
        
        setUpElements()
        
        dayTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        dayTextField.delegate = self
        monthTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        monthTextField.delegate = self
        yearTextField.smartInsertDeleteType = UITextSmartInsertDeleteType.no
        yearTextField.delegate = self
    }
    
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        return textField.shouldChangeCustomOtp(textField: textField, string: string)
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    @IBAction func nextButtonPressed(){
        if (dayTextField.text!.count == 2 && monthTextField.text!.count == 2 && yearTextField.text!.count == 4){
            
            //Checks for valid birthday input
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            
            if let date = dateFormatter.date(from: "\(yearTextField.text!)-\(monthTextField.text!)-\(dayTextField.text!)"
            ) {
                print(date)
                errorLabel.isHidden = true
                let birthday = monthTextField.text! + "/" + dayTextField.text! + "/" + yearTextField.text!
                UserDefaults.standard.set(dayTextField.text, forKey:"birthdayDay")
                UserDefaults.standard.set(monthTextField.text, forKey:"birthdayMonth")
                UserDefaults.standard.set(yearTextField.text, forKey:"birthdayYear")
                UserDefaults.standard.set(birthday, forKey:"birthday")
                let controller = storyboard?.instantiateViewController(identifier: "schoolViewController") as! SchoolViewController
                controller.modalTransitionStyle = .crossDissolve
                controller.modalPresentationStyle = .fullScreen
                present(controller, animated: true, completion: nil)            }
            else {
                errorLabel.isHidden = false
                errorLabel.text = "Please enter a valid date"
            }
        }
        else{
            errorLabel.isHidden = false
            errorLabel.text = "Please enter valid inputs in all fields"
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "genderViewController") as! GenderViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    
}

extension UITextField {
    func shouldChangeCustomOtp(textField:UITextField, string: String) ->Bool {
        
        if textField.tag == 1 || textField.tag == 2{
            //Check if textField has two chacraters
            if ((textField.text?.count)! == 1  && string.count > 0) {
                let nextTag = textField.tag + 1;
                // get next responder
                var nextResponder = textField.superview?.viewWithTag(nextTag);
                if (nextResponder == nil) {
                    nextResponder = textField.superview?.viewWithTag(1);
                }
                
                textField.text = textField.text! + string;
                //write here your last textfield tag
                if textField.tag == 3 {
                    //Dissmiss keyboard on last entry
                    textField.resignFirstResponder()
                }
                else {
                    //Appear keyboard
                    nextResponder?.becomeFirstResponder();
                }
                return false;
            } else if ((textField.text?.count)! == 1  && string.count == 0) {// on deleteing value from Textfield
                
                let previousTag = textField.tag - 1;
                // get prev responder
                var previousResponder = textField.superview?.viewWithTag(previousTag);
                if (previousResponder == nil) {
                    previousResponder = textField.superview?.viewWithTag(1);
                }
                textField.text = "";
                previousResponder?.becomeFirstResponder();
                return false
            }
        }
        else if textField.tag == 3{
            //Check if textField has four chacraters
            if ((textField.text?.count)! == 3  && string.count > 0) {
                let nextTag = textField.tag + 1;
                // get next responder
                var nextResponder = textField.superview?.viewWithTag(nextTag);
                if (nextResponder == nil) {
                    nextResponder = textField.superview?.viewWithTag(1);
                }
                
                textField.text = textField.text! + string;
                //write here your last textfield tag
                if textField.tag == 3 {
                    //Dissmiss keyboard on last entry
                    textField.resignFirstResponder()
                }
                else {
                    //Appear keyboard
                    nextResponder?.becomeFirstResponder();
                }
                return false;
            } else if ((textField.text?.count)! == 3  && string.count == 0) {// on deleteing value from Textfield
                
                let previousTag = textField.tag - 1;
                // get prev responder
                var previousResponder = textField.superview?.viewWithTag(previousTag);
                if (previousResponder == nil) {
                    previousResponder = textField.superview?.viewWithTag(1);
                }
                textField.text = "";
                previousResponder?.becomeFirstResponder();
                return false
            }
        }
        return true
    }
    
}
