//
//  PositionViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 9/14/22.
//

import UIKit

class PositionViewController: UIViewController {
    
    @IBOutlet weak var positionTextField: UITextField!
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
        
        if UserDefaults.standard.string(forKey: "position") != nil{
            let positionInfo = UserDefaults.standard.string(forKey: "position")!
            positionTextField.text = positionInfo
        }
        setUpElements()
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if positionTextField.text == ""{
            errorLabel.isHidden = false
            errorLabel.text = "Please enter information in all fields"
        }
        else{
            errorLabel.isHidden = true
            UserDefaults.standard.set(positionTextField.text, forKey:"position")
            let controller = storyboard?.instantiateViewController(identifier: "profilePictureViewController") as! ProfilePictureViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }

    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "companyViewController") as! CompanyViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }

}
