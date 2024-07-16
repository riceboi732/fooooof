//
//  ClassYearViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 9/14/22.
//

import UIKit

class ClassYearViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var classYearTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        classYearTextField.delegate = self
        classYearTextField.keyboardType = .asciiCapableNumberPad
        super.viewDidLoad()
        
        nextButton.widthAnchor.constraint(equalToConstant: 35).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
        nextButton.tintColor = UIColor.white
        nextButton.titleLabel!.textColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        classYearTextField.keyboardType = .asciiCapableNumberPad
        
        if UserDefaults.standard.string(forKey: "classyear") != nil{
            let classyearInfo = UserDefaults.standard.string(forKey: "classyear")!
            classYearTextField.text = classyearInfo
        }
        setUpElements()
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if classYearTextField.text == ""{
            errorLabel.isHidden = false
            errorLabel.text = "Please enter information in all fields"
        }
        else{
            errorLabel.isHidden = true
            UserDefaults.standard.set(classYearTextField.text, forKey:"classyear")
            let controller = storyboard?.instantiateViewController(identifier: "majorViewController") as! MajorViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "schoolViewController") as! SchoolViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }


}
