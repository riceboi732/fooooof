import UIKit

class ProfessionalInfoViewController: UIViewController {
    
    @IBOutlet weak var companyTextField: UITextField!
    @IBOutlet weak var positionTextField: UITextField!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.string(forKey: "company") != nil && UserDefaults.standard.string(forKey: "position") != nil{
            let companyInfo = UserDefaults.standard.string(forKey: "company")!
            companyTextField.text = companyInfo
            let positionInfo = UserDefaults.standard.string(forKey: "position")!
            positionTextField.text = positionInfo
        }
        setUpElements()
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    @IBAction func nextButtonTapped(_ sender: Any) {
        if companyTextField.text == "" || positionTextField.text == ""{
            errorLabel.isHidden = false
            errorLabel.text = "Please enter information in all fields"
        }
        else{
            errorLabel.isHidden = true
            UserDefaults.standard.set(companyTextField.text, forKey:"company")
            UserDefaults.standard.set(positionTextField.text, forKey:"position")
            let controller = storyboard?.instantiateViewController(identifier: "favLocationViewController") as! FavLocationViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }

    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "academicInfoViewController") as! MajorViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }

}
