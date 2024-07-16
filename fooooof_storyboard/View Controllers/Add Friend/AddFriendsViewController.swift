//
//  AddFriendsViewController.swift
//  fooooof_storyboard
//
//  Created by Jessica Chen on 9/26/22.
//

import UIKit

class AddFriendsViewController: UIViewController {
    
    @IBOutlet weak var contactButton: UIButton!
    @IBOutlet weak var contactsText: UIButton!
    @IBOutlet weak var usernameButton: UIButton!
    @IBOutlet weak var usernameTextButton: UIButton!
    @IBOutlet weak var phoneButton: UIButton!
    @IBOutlet weak var phoneText: UIButton!
    @IBOutlet weak var quitButton: UIButton!
    
    
    @IBAction func returnToHome(segue: UIStoryboardSegue){
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpButtons()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    
    func setUpButtons() {
        quitButton.setTitle("", for: .normal)
        
        contactButton.setTitle("", for: .normal)
        contactButton.layer.shadowRadius = 1
        contactButton.layer.shadowOpacity = 0.2
        contactButton.layer.shadowOffset = CGSize(width: 0.1, height: 0.1)
        contactButton.layer.shadowColor = UIColor.black.cgColor
        
        contactsText.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.left
        
        usernameButton.setTitle("", for: .normal)
        usernameButton.layer.shadowRadius = 1
        usernameButton.layer.shadowOpacity = 0.2
        usernameButton.layer.shadowOffset = CGSize(width: 0.1, height: 0.1)
        usernameButton.layer.shadowColor = UIColor.black.cgColor
        
        usernameTextButton.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.left
        
        phoneButton.setTitle("", for: .normal)
        phoneButton.layer.shadowRadius = 1
        phoneButton.layer.shadowOpacity = 0.2
        phoneButton.layer.shadowOffset = CGSize(width: 0.1, height: 0.1)
        phoneButton.layer.shadowColor = UIColor.black.cgColor
        
        phoneText.contentHorizontalAlignment = UIControl.ContentHorizontalAlignment.left
    }
}
