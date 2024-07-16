import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController {
    @IBOutlet weak var signUpButton: UIButton!
    @IBOutlet weak var loginButton: UIButton!
    
    override func viewDidLoad() {
        UserDefaults.standard.removeObject(forKey: "phone")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.removeObject(forKey: "firstname")
        UserDefaults.standard.removeObject(forKey: "lastname")
        UserDefaults.standard.removeObject(forKey: "pronouns")
        UserDefaults.standard.removeObject(forKey: "birthday")
        UserDefaults.standard.removeObject(forKey: "major")
        UserDefaults.standard.removeObject(forKey: "college")
        UserDefaults.standard.removeObject(forKey: "classyear")
        UserDefaults.standard.removeObject(forKey: "position")
        UserDefaults.standard.removeObject(forKey: "location1")
        UserDefaults.standard.removeObject(forKey: "location2")
        UserDefaults.standard.removeObject(forKey: "location3")
        UserDefaults.standard.removeObject(forKey: "interests")
        super.viewDidLoad()
        if UserDefaults.standard.bool(forKey: "isUserLoggedIn") == true{
            let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            navigationController?.pushViewController(homeViewController, animated: false)
        }
    }
    
    @IBAction func didTapLogInButton(){
        let controller = storyboard?.instantiateViewController(identifier: "loginPhoneViewController") as! LoginPhoneViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let backItem = UIBarButtonItem()
        backItem.title = "Back"
        navigationItem.backBarButtonItem = backItem
    }
}

//Function that allows the keyboard to disappear once user clicks outside of it for all screens
extension UIViewController {
    override open func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        view.endEditing(true)
    }
}
