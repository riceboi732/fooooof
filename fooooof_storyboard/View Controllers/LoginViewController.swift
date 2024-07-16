import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

class LoginViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    @IBOutlet weak var backButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.bool(forKey: "isUserLoggedIn") == true{
            let homeViewController = storyboard?.instantiateViewController(withIdentifier: "HomeViewController") as! HomeViewController
            navigationController?.pushViewController(homeViewController, animated: false)
        }
        setUpElements()
    }

    
    func setUpElements() {
        errorLabel.alpha = 0

        Utilities.styleTextField(emailTextField)
        Utilities.styleTextField(passwordTextField) 
        Utilities.styleFilledButton(loginButton)
    }

    @IBAction func loginTapped(_ sender: Any) {
        let error = validateFields()
        
        if error != nil {
            showError(error!)
        }
        else {
            let email = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            let password = passwordTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
            
            Auth.auth().signIn(withEmail: email, password: password) { [weak self] (result, error) in
                guard let strongSelf = self else {
                    return
                }
                if error != nil {
                    strongSelf.errorLabel.text = error!.localizedDescription
                    strongSelf.errorLabel.alpha = 1
                }
                else {
                    UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
                    let controller = strongSelf.storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
                    strongSelf.view.window?.rootViewController = controller
                    strongSelf.view.window?.makeKeyAndVisible()
                    //Note: the view transition below is buggy because pins will not appear if we use below transition. Use transition code above if transitioning to HomeViewController in the future.
//                    let controller = self.storyboard?.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
//                    controller.modalPresentationStyle = .fullScreen
//                    self.present(controller, animated: true, completion: nil)
                }
            }
        }
    }
    
    func validateFields() -> String? {
        if emailTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" || passwordTextField.text?.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
            return "Please fill in all the fields."
        }
        
        let cleanedEmail = emailTextField.text!.trimmingCharacters(in: .whitespacesAndNewlines)
        
        if Utilities.isEmailValid(cleanedEmail) == false {
            return "Invalid email."
        }
        
        return nil
    }
    
    func showError(_ message:String) {
        errorLabel.text = message
        errorLabel.alpha = 1
    }

    func transitionToHome() {
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    @IBAction func backTapped(_ sender: Any) {
        let viewController = storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController
        
        view.window?.rootViewController = viewController
        view.window?.makeKeyAndVisible()
    }
}

