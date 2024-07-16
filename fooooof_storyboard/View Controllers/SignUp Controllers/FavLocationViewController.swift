//import UIKit
//
//class FavLocationViewController: UIViewController {
//
//    @IBOutlet weak var location1TextField: UITextField!
//    @IBOutlet weak var location2TextField: UITextField!
//    @IBOutlet weak var location3TextField: UITextField!
//    @IBOutlet weak var errorLabel: UILabel!
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        if UserDefaults.standard.string(forKey: "location1") != nil && UserDefaults.standard.string(forKey: "location2") != nil && UserDefaults.standard.string(forKey: "location3") != nil{
//            let location1Info = UserDefaults.standard.string(forKey: "location1")!
//            location1TextField.text = location1Info
//            let location2Info = UserDefaults.standard.string(forKey: "location2")!
//            location2TextField.text = location2Info
//            let location3Info = UserDefaults.standard.string(forKey: "location3")!
//            location3TextField.text = location3Info
//        }
//        setUpElements()
//    }
//
//    func setUpElements() {
//        errorLabel.isHidden = true
//    }
//
//
//    @IBAction func didTapNextButton(_ sender: Any) {
//
//        let location1strings : String! = location1TextField.text
//        let location2strings : String! = location2TextField.text
//        let location3strings : String! = location3TextField.text
//        let spaces = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters)
//        let location1words = location1strings.components(separatedBy: spaces)
//        let location2words = location2strings.components(separatedBy: spaces)
//        let location3words = location3strings.components(separatedBy: spaces)
//
//        if location1words.count > 6 || location2words.count > 6 || location3words.count > 6{
//            errorLabel.isHidden = false
//            errorLabel.text = "Please make sure that all locations are 6 words or less."
//        }
//        else if location1TextField.text == "" || location2TextField.text == "" || location3TextField.text == ""{
//            errorLabel.isHidden = false
//            errorLabel.text = "Please enter information in all fields"
//        }
//        else{
//            errorLabel.isHidden = true
//            UserDefaults.standard.set(location1TextField.text, forKey:"location1")
//            UserDefaults.standard.set(location2TextField.text, forKey:"location2")
//            UserDefaults.standard.set(location3TextField.text, forKey:"location3")
//            let controller = storyboard?.instantiateViewController(identifier: "interestInfoViewController") as! InterestInfoViewController
//            controller.modalTransitionStyle = .crossDissolve
//            controller.modalPresentationStyle = .fullScreen
//            present(controller, animated: true, completion: nil)
//        }
//    }
//
//    @IBAction func didTapBackButton(_ sender: Any) {
//        let controller = storyboard?.instantiateViewController(identifier: "professionalInfoViewController") as! ProfessionalInfoViewController
//        controller.modalTransitionStyle = .crossDissolve
//        controller.modalPresentationStyle = .fullScreen
//        present(controller, animated: true, completion: nil)
//    }
//
//}
