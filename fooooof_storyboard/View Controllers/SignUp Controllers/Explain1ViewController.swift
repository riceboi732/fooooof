//
//  Explain1ViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 9/9/22.
//

import UIKit

class Explain1ViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButtonArrow: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButtonArrow.widthAnchor.constraint(equalToConstant: 50).isActive = true
        nextButtonArrow.layer.cornerRadius = nextButtonArrow.frame.size.width/2
        nextButtonArrow.layer.masksToBounds = true
        nextButtonArrow.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButtonArrow.titleLabel!.textColor = UIColor.white
        nextButtonArrow.layer.borderWidth = 1
        nextButtonArrow.layer.borderColor = CGColor(red: (1), green: (1), blue: (1), alpha: 1)
        
        backButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        backButton.layer.cornerRadius = backButton.frame.size.width/2
        backButton.layer.masksToBounds = true
        backButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        backButton.titleLabel!.textColor = UIColor.white
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = CGColor(red: (1), green: (1), blue: (1), alpha: 1)
    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "signUpViewController") as! SignUpViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonArrowPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "explain2ViewController") as! Explain2ViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
}
