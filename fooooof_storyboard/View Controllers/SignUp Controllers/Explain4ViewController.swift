//
//  Explain4ViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 9/9/22.
//

import UIKit

class Explain4ViewController: UIViewController {

    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        nextButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
        nextButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButton.titleLabel!.textColor = UIColor.white
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = CGColor(red: (1), green: (1), blue: (1), alpha: 1)
        
        backButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        backButton.layer.cornerRadius = backButton.frame.size.width/2
        backButton.layer.masksToBounds = true
        backButton.tintColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        backButton.titleLabel!.textColor = UIColor.white
        backButton.layer.borderWidth = 1
        backButton.layer.borderColor = CGColor(red: (1), green: (1), blue: (1), alpha: 1)

    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "explain3ViewController") as! Explain3ViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func nextButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "explained5ViewController") as! Explained5ViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
}
