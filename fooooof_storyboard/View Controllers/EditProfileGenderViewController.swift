//
//  EditProfileGenderViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 3/8/23.
//

import UIKit
import FirebaseFirestore
import FirebaseAuth

class EditProfileGenderViewController: UIViewController {
    
    @IBOutlet weak var maleButton: UIButton!
    @IBOutlet weak var femaleButton: UIButton!
    @IBOutlet weak var otherButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var saveChangesButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var fieldLabel: UILabel!
    
    var field = ""
    var value = ""
    let db = Firestore.firestore()
    let selfUid = Auth.auth().currentUser!.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fieldLabel.text = field
        
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
        
        //loading current gender choice from EditProfileViewController
        if value == "female"{
            femaleButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            femaleButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))        }
        
        else if value == "male"{
            maleButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            maleButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))        }
        
        else if value == "other"{
            otherButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
            otherButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))        }

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
    
    @IBAction func backButtonTapped(sender: AnyObject) {
        let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
        }

    
    
    @IBAction func saveChangesButtonTapped(_ sender: AnyObject) {
        let selfProfile = db.collection("users").document(selfUid)

        if maleButton.tintColor == UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000)){
            errorLabel.isHidden = true
            value = "male"
            errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
            selfProfile.setData(["gender":"male"], merge: true)
            let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
        else if femaleButton.tintColor == UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000)){
            errorLabel.isHidden = true
            value = "female"
            errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
            selfProfile.setData(["gender":"female"], merge: true)
            let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
        else if otherButton.tintColor == UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000)){
            errorLabel.isHidden = true
            value = "other"
            errorLabel.textColor = UIColor.init(red:25/255, green: 135/255, blue: 84/255, alpha: 1)
            selfProfile.setData(["gender":"other"], merge: true)
            let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
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
