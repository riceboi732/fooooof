import UIKit

class NotificationCenterTestingViewController: UIViewController {

    
    @IBOutlet weak var label: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(didGetNotification(_:)), name: Notification.Name("com.fooooof.didGetNotification"), object: nil)
    }
    
    @objc func didGetNotification(_ notification: Notification){
        let text = notification.object as! String?
        label.text = text
    }
    


}
