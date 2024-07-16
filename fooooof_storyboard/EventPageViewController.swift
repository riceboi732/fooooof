//
//  EventPageViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 5/11/23.
//

import UIKit

class EventPageViewController: UIViewController {

    @IBOutlet weak var createEventButton: UIButton!
    
    
    @IBAction func createEventButtonPressed(_ sender: Any){
        let controller = storyboard?.instantiateViewController(identifier: "eventCreationViewController") as! EventCreationViewController
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

    }
    


}
