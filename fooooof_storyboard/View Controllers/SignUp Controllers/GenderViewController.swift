//
//  GenderViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 9/13/22.
//

import UIKit

class GenderViewController: UIViewController {
    
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
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
        
        //male button parameters
        maleButton.layer.cornerRadius = maleButton.frame.size.width/2
        maleButton.layer.masksToBounds = true
        maleButton.tintColor = UIColor.white
        maleButton.titleLabel!.textColor = UIColor.black
        maleButton.layer.borderWidth = 1
        maleButton.layer.borderColor = UIColor.gray.cgColor
        
        //female button parameters
        femaleButton.layer.cornerRadius = femaleButton.frame.size.width/2
        femaleButton.layer.masksToBounds = true
        femaleButton.tintColor = UIColor.white
        femaleButton.titleLabel!.textColor = UIColor.black
        femaleButton.layer.borderWidth = 1
        femaleButton.layer.borderColor = UIColor.gray.cgColor
        
        //other button parameters
        otherButton.layer.cornerRadius = otherButton.frame.size.width/2
        otherButton.layer.masksToBounds = true
        otherButton.tintColor = UIColor.white
        otherButton.titleLabel!.textColor = UIColor.black
        otherButton.layer.borderWidth = 1
        otherButton.layer.borderColor = UIColor.gray.cgColor
        
        if UserDefaults.standard.string(forKey: "gender") == "Female"{
            let usernameInfo = UserDefaults.standard.string(forKey: "username")!
            femaleButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            femaleButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))        }
        
        else if UserDefaults.standard.string(forKey: "gender") == "Male"{
            let usernameInfo = UserDefaults.standard.string(forKey: "username")!
            maleButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            maleButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))        }
        
        else if UserDefaults.standard.string(forKey: "gender") == "Other"{
            let usernameInfo = UserDefaults.standard.string(forKey: "username")!
            otherButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            otherButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))        }
    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "personalInfoViewController") as! PersonalInfoViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func maleButtonTapped(sender: AnyObject) {
        if maleButton.tintColor == UIColor.white {
            maleButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            maleButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            femaleButton.tintColor = UIColor.white
            femaleButton.layer.borderColor = UIColor.gray.cgColor
            otherButton.tintColor = UIColor.white
            otherButton.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    @IBAction func femaleButtonTapped(sender: AnyObject) {
        if femaleButton.tintColor == UIColor.white {
            femaleButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            femaleButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            maleButton.tintColor = UIColor.white
            maleButton.layer.borderColor = UIColor.gray.cgColor
            otherButton.tintColor = UIColor.white
            otherButton.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    @IBAction func otherButtonTapped(sender: AnyObject) {
        if otherButton.tintColor == UIColor.white {
            otherButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            otherButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            femaleButton.tintColor = UIColor.white
            femaleButton.layer.borderColor = UIColor.gray.cgColor
            maleButton.tintColor = UIColor.white
            maleButton.layer.borderColor = UIColor.gray.cgColor
        }
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if maleButton.tintColor == UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000)){
            errorLabel.isHidden = true
            UserDefaults.standard.set("Male", forKey:"gender")
            print("gender is male")
            let controller = storyboard?.instantiateViewController(identifier: "birthdayViewController") as! BirthdayViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
        else if femaleButton.tintColor == UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000)){
            errorLabel.isHidden = true
            UserDefaults.standard.set("Female", forKey:"gender")
            print("gender is female")
            let controller = storyboard?.instantiateViewController(identifier: "birthdayViewController") as! BirthdayViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
        else if otherButton.tintColor == UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000)){
            errorLabel.isHidden = true
            UserDefaults.standard.set("Other", forKey:"gender")
            print("gender is other")
            let controller = storyboard?.instantiateViewController(identifier: "birthdayViewController") as! BirthdayViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
        else{
            errorLabel.isHidden = false
            errorLabel.text = "Please choose a gender"
        }
    }
}
