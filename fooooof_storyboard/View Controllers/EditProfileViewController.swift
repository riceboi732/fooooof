import UIKit
import Photos
import PhotosUI
import BSImagePicker
import FirebaseAuth
import Firebase
import FirebaseFirestore
import Foundation
import FirebaseMessaging
import TTGTagCollectionView
import AudioToolbox

class EditProfileViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var editButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var chatButton: UIButton!
    @IBOutlet weak var profileButton: UIButton!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var usernameButton: UIButton!
    @IBOutlet weak var usernameBigButton: UIButton!
    @IBOutlet weak var genderLabel: UILabel!
    @IBOutlet weak var genderButton: UIButton!
    @IBOutlet weak var genderBigButton: UIButton!
    @IBOutlet weak var schoolLabel: UILabel!
    @IBOutlet weak var schoolButton: UIButton!
    @IBOutlet weak var schoolBigButton: UIButton!
    @IBOutlet weak var classLabel: UILabel!
    @IBOutlet weak var classButton: UIButton!
    @IBOutlet weak var classBigButton: UIButton!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet weak var majorButton: UIButton!
    @IBOutlet weak var majorBigButton: UIButton!
    @IBOutlet weak var companyLabel: UILabel!
    @IBOutlet weak var companyButton: UIButton!
    @IBOutlet weak var companyBigButton: UIButton!
    @IBOutlet weak var positionLabel: UILabel!
    @IBOutlet weak var positionButton: UIButton!
    @IBOutlet weak var positionBigButton: UIButton!
    
    var userDataDict:[String: String] = [:]
    
    //    var profilePictureURL: String? = ""
    //
    //    var image: UIImage? = nil
    //
//    private let storage = Storage.storage().reference()
    
//    let imagePicker = UIImagePickerController()

        
    override func viewDidLoad() {
        super.viewDidLoad()
        scrollView.contentSize = CGSizeMake(view.frame.width, view.frame.height+100)
        buttonLabelSetup()
//        imagePicker.delegate = self
//        imagePicker.allowsEditing = true
        fetchUserData()
        //shadow to edit & preview buttons
        editButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        editButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        editButton.layer.shadowOpacity = 0.5
        editButton.layer.shadowRadius = 0.5
        editButton.layer.masksToBounds = false
        editButton.layer.cornerRadius = 0
        previewButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        previewButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        previewButton.layer.shadowOpacity = 0.5
        previewButton.layer.shadowRadius = 0.5
        previewButton.layer.masksToBounds = false
        previewButton.layer.cornerRadius = 0
        editButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 14)
        previewButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 14)
    }
    
    func buttonLabelSetup() {
        mapButton.setTitle("", for: .normal)
        chatButton.setTitle("", for: .normal)
        profileButton.setTitle("", for: .normal)
        editButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        previewButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        usernameButton.setTitle("", for: .normal)
        usernameBigButton.setTitle("", for: .normal)
        genderButton.setTitle("", for: .normal)
        genderBigButton.setTitle("", for: .normal)
        schoolButton.setTitle("", for: .normal)
        schoolBigButton.setTitle("", for: .normal)
        classButton.setTitle("", for: .normal)
        classBigButton.setTitle("", for: .normal)
        majorButton.setTitle("", for: .normal)
        majorBigButton.setTitle("", for: .normal)
        companyButton.setTitle("", for: .normal)
        companyBigButton.setTitle("", for: .normal)
        positionButton.setTitle("", for: .normal)
        positionBigButton.setTitle("", for: .normal)
    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "personalProfileViewController") as! PersonalProfileViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func returnToHome(segue: UIStoryboardSegue){
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    @IBAction func transitionToMessages(_ sender: Any) {
//        let vc = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.navigationController) as! UINavigationController
//        view.window?.rootViewController = vc
//        view.window?.makeKeyAndVisible()
        let vc = storyboard?.instantiateViewController(withIdentifier: "Messages1ViewController") as! Messages1ViewController
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changeUsername(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "personalProfileSingle") as! PersonalProfileSingleViewController
        vc.field = "Username"
        vc.value = usernameLabel.text ?? "username does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changeGender(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "editProfileGenderViewController") as! EditProfileGenderViewController
        vc.field = "Gender"
        vc.value = genderLabel.text ?? "gender does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changeSchool(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "personalProfileSingle") as! PersonalProfileSingleViewController
        vc.field = "School"
        vc.value = schoolLabel.text ?? "school does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changeClass(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "personalProfileSingle") as! PersonalProfileSingleViewController
        vc.field = "Class"
        vc.value = classLabel.text ?? "class does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changeMajor(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "personalProfileSingle") as! PersonalProfileSingleViewController
        vc.field = "Major"
        vc.value = majorLabel.text ?? "major does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changeCompany(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "personalProfileSingle") as! PersonalProfileSingleViewController
        vc.field = "Company"
        vc.value = companyLabel.text ?? "company does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func changePosition(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "personalProfileSingle") as! PersonalProfileSingleViewController
        vc.field = "Current position"
        vc.value = positionLabel.text ?? "position does not exist"
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    
    
    
    func fetchUserData(){
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userUid).getDocument { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                if let username = dictionary["username"] {
                    strongSelf.usernameLabel.text = (username as! String)
                }
                if let gender = dictionary["gender"] {
                    strongSelf.genderLabel.text = (gender as! String)
                }
                if let school = dictionary["college"] {
                    strongSelf.schoolLabel.text = (school as! String)
                }
                if let classYear = dictionary["classYear"] {
                    strongSelf.classLabel.text = (classYear as! String)
                }
                if let major = dictionary["major"] {
                    strongSelf.majorLabel.text = (major as! String)
                }
                if let company = dictionary["company"] {
                    strongSelf.companyLabel.text = (company as! String)
                }
                if let position = dictionary["position"] {
                    strongSelf.positionLabel.text = (position as! String)
                }
//                self.interests.setTitle((dictionary["interests"] as! [String]).joined(separator: ", "), for: .normal)
//                self.profilePictureURL = (dictionary["profileImageUrl"] as! String)
//                guard let url = URL(string: dictionary["profileImageUrl"] as! String) else { return }
    //            self.profileImageView.loadFrom(URLAddress: (dictionary["profileImageUrl"] as! String))
//                self.profilePicture.sd_setImage(with: url)
//                self.profilePicture.loadFrom(URLAddress: (dictionary["profileImageUrl"] as! String))
////                self.profilePicture.sd_setImage(with: (dictionary["profileImageUrl"] as! URL))
            }
        }
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        view.addSubview(scrollView)
//        scrollView.contentSize = CGSize(width: view.frame.size.width, height: 1500)
//    }
    
//    @IBAction func didTapSelectProfilePic(){
//
//        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
//
//        alert.addAction(UIAlertAction(title: "Photo Gallary", style: .default, handler: { (button) in
//            self.imagePicker.sourceType = .photoLibrary
//            self.present(self.imagePicker, animated: true, completion: nil)
//        }))
//
//        alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { (button) in
//            self.imagePicker.sourceType = .camera
//            self.present(self.imagePicker, animated: true, completion: nil)
//        }))
//
//        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
//
//        present(alert, animated: true, completion: nil)
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:
//                               [UIImagePickerController.InfoKey: Any]){
//        if let imageSelected = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
//            image = imageSelected
//            profilePicture.image = imageSelected
//            profilePictureURL = ""
//        }
//        picker.dismiss(animated: true, completion: nil)
//    }
    
//    @IBAction func saveButtonPressed(){
//        let firstname = firstName.text
//        let lastname = lastName.text
//        let birthday = birthday.text
//        let pronouns = pronouns.text
//        let classYear = classyear.text
//        let major = major.text
//        let college = college.text
//        let position = position.text
//        let company = company.text
////        let location1 = location1.text
////        let location2 = location2.text
////        let location3 = location3.text
//
//        //If the user hasn't changed their profile, keep original
//        if !profilePictureURL!.isEmpty{
//            guard let userUid = Auth.auth().currentUser?.uid else { return }
//            let db = Firestore.firestore()
//            db.collection("users").document(userUid).updateData([
//                "firstName": firstname!,
//                "lastName": lastname!,
//                "pronouns": pronouns!,
//                "birthday": birthday!,
//                "major": major!,
//                "college": college!,
//                "position": position!,
//                "company": company!,
//                "classYear": classYear!,
////                "location1": location1!,
////                "location2": location2!,
////                "location3": location3!,
//                "profileImageUrl": profilePictureURL!
//            ])
//
//            let controller = storyboard?.instantiateViewController(identifier: "personalProfileViewController") as! PersonalProfileViewController
//            controller.modalTransitionStyle = .crossDissolve
//            controller.modalPresentationStyle = .fullScreen
//            present(controller, animated: true, completion: nil)
//        }
//
//        //if the user changes the profile
//        else{
//            guard let imageSelected = self.image else{
//                print("Avatar is nil")
//                return
//            }
//
//            guard let imageData = imageSelected.jpegData(compressionQuality: 0.4) else{
//                return
//            }
//            guard let userUid = Auth.auth().currentUser?.uid else { return }
//            let db = Firestore.firestore()
//            db.collection("users").document(userUid).updateData([
//                "firstName": firstname!,
//                "lastName": lastname!,
//                "pronouns": pronouns!,
//                "birthday": birthday!,
//                "major": major!,
//                "college": college!,
//                "position": position!,
//                "company": company!,
//                "classYear": classYear!,
//                "profileImageUrl": ""
//            ])
//
//            let storageRef = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
//            let storageProfileRef = storageRef.child("profile").child(userUid)
//
//            let metaData = StorageMetadata()
//            metaData.contentType = "image/jpg"
//            storageProfileRef.putData(imageData, metadata: metaData, completion: {
//                (storageMetaData, error) in
//                if error != nil{
//                    return
//                }
//                storageProfileRef.downloadURL(completion: {(url, error) in
//                    if let metaImageUrl = url?.absoluteString{
//
//                        db.collection("users").document(userUid).updateData([
//                            "profileImageUrl": metaImageUrl
//                        ])
//                    }
//                })
//            })
//            let controller = storyboard?.instantiateViewController(identifier: "personalProfileViewController") as! PersonalProfileViewController
//            controller.modalTransitionStyle = .crossDissolve
//            controller.modalPresentationStyle = .fullScreen
//            present(controller, animated: true, completion: nil)
//        }
//
//    }
    
//    @IBAction func interestButtonPressed(){
//        let controller = storyboard?.instantiateViewController(identifier: "editProfileInterestsViewController") as! EditProfileInterestsViewController
//        controller.modalTransitionStyle = .crossDissolve
//        controller.modalPresentationStyle = .fullScreen
//        present(controller, animated: true, completion: nil)
//    }
    
}

