//import Photos
//import PhotosUI
//import BSImagePicker
//import UIKit
//import FirebaseAuth
//import Firebase
//import FirebaseFirestore
//import FirebaseStorage
//import FirebaseDatabase
//
//class FinalProfileCreationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//    
//    @IBOutlet var saveButton: UIButton!
//    @IBOutlet var backButton: UIButton!
//    @IBOutlet var profilePicture: UIImageView!
//    @IBOutlet weak var selectProfiePicButton: UIButton!
//    
//    var image: UIImage? = nil
//    
//    private let storage = Storage.storage().reference()
//    
//    let imagePicker = UIImagePickerController()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        imagePicker.delegate = self
//        imagePicker.allowsEditing = true
//        
//    }
//    
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
//        }
//        picker.dismiss(animated: true, completion: nil)
//    }
//    
//    @IBAction func didTapSave(){
//        let phone = UserDefaults.standard.string(forKey: "phone")!
//        let email = UserDefaults.standard.string(forKey: "email")!
//        let username = UserDefaults.standard.string(forKey: "username")!
//        let firstname = UserDefaults.standard.string(forKey: "firstname")!
//        let lastname = UserDefaults.standard.string(forKey: "lastname")!
//        let pronouns = UserDefaults.standard.string(forKey: "pronouns")!
//        let birthday = UserDefaults.standard.string(forKey: "birthday")!
//        let major = UserDefaults.standard.string(forKey: "major")!
//        let college = UserDefaults.standard.string(forKey: "college")!
//        let classYear = UserDefaults.standard.string(forKey: "classyear")!
//        let company = UserDefaults.standard.string(forKey: "company")!
//        let position = UserDefaults.standard.string(forKey: "position")!
//        let location1 = UserDefaults.standard.string(forKey: "location1")!
//        let location2 = UserDefaults.standard.string(forKey: "location2")!
//        let location3 = UserDefaults.standard.string(forKey: "location3")!
//        let interests = UserDefaults.standard.stringArray(forKey: "interests") ?? [String]()
//        let code = UserDefaults.standard.string(forKey: "verificationCode")!
//        let verification_id = UserDefaults.standard.string(forKey: "verification_id")!
//        
//        guard let imageSelected = self.image else{
//            print("Avatar is nil")
//            return
//        }
//        
//        guard let imageData = imageSelected.jpegData(compressionQuality: 0.4) else{
//            return
//        }
//        
//        let credential = PhoneAuthProvider.provider().credential(withVerificationID: verification_id, verificationCode: code)
//        Auth.auth().settings?.isAppVerificationDisabledForTesting = true
//        Auth.auth().signIn(with: credential)
//        {(authData, error) in
//            if error != nil{
//                print(error.debugDescription)
//            }
//            else{
//                let db = Firestore.firestore()
//                db.collection("users").document(authData!.user.uid).setData([
//                    "firstName": firstname,
//                    "lastName": lastname,
//                    "phone": phone,
//                    "email": email,
//                    "username": username,
//                    "pronouns": pronouns,
//                    "birthday": birthday,
//                    "interests": interests,
//                    "major": major,
//                    "college": college,
//                    "position": position,
//                    "company": company,
//                    "classYear": classYear,
//                    "location1": location1,
//                    "location2": location2,
//                    "location3": location3,
//                    "profileImageUrl": "",
//                    "uid": authData!.user.uid,
//                    "chatRoomCount": 0,
//                    "indexCount": 0
//                ])
//                
//                let storageRef = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
//                let storageProfileRef = storageRef.child("profile").child(authData!.user.uid)
//                
//                let metaData = StorageMetadata()
//                metaData.contentType = "image/jpg"
//                storageProfileRef.putData(imageData, metadata: metaData, completion: {
//                    (storageMetaData, error) in
//                    if error != nil{
//                        return
//                    }
//                    storageProfileRef.downloadURL(completion: {(url, error) in
//                        if let metaImageUrl = url?.absoluteString{
//                            
//                            db.collection("users").document(authData!.user.uid).updateData([
//                                "profileImageUrl": metaImageUrl
//                            ])
//                        }
//                    })
//                })
//                UserDefaults.standard.removeObject(forKey: "phone")
//                UserDefaults.standard.removeObject(forKey: "email")
//                UserDefaults.standard.removeObject(forKey: "username")
//                UserDefaults.standard.removeObject(forKey: "password")
//                UserDefaults.standard.removeObject(forKey: "firstname")
//                UserDefaults.standard.removeObject(forKey: "lastname")
//                UserDefaults.standard.removeObject(forKey: "pronouns")
//                UserDefaults.standard.removeObject(forKey: "birthday")
//                UserDefaults.standard.removeObject(forKey: "major")
//                UserDefaults.standard.removeObject(forKey: "college")
//                UserDefaults.standard.removeObject(forKey: "classyear")
//                UserDefaults.standard.removeObject(forKey: "position")
//                UserDefaults.standard.removeObject(forKey: "location1")
//                UserDefaults.standard.removeObject(forKey: "location2")
//                UserDefaults.standard.removeObject(forKey: "location3")
//                UserDefaults.standard.removeObject(forKey: "interests")
//                UserDefaults.standard.removeObject(forKey: "verificationCode")
//                UserDefaults.standard.removeObject(forKey: "verification_id")
//                
//                UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
//                let controller = self.storyboard?.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
//                controller.modalPresentationStyle = .fullScreen
//                self.present(controller, animated: true, completion: nil)
//            }
//        }
//    }
//    
//    
//    
//    //        Auth.auth().createUser(withEmail: email, password: password) { result, error in
//    //                if error != nil {
//    //                    return
//    //                }
//    //            else {
//    //                    let db = Firestore.firestore()
//    //                    db.collection("users").document(result!.user.uid).setData([
//    //                        "firstName": firstname,
//    //                        "lastName": lastname,
//    //                        "phone": phone,
//    //                        "email": email,
//    //                        "username": username,
//    //                        "pronouns": pronouns,
//    //                        "birthday": birthday,
//    //                        "interests": interests,
//    //                        "major": major,
//    //                        "college": college,
//    //                        "position": position,
//    //                        "company": company,
//    //                        "classYear": classYear,
//    //                        "location1": location1,
//    //                        "location2": location2,
//    //                        "location3": location3,
//    //                        "profileImageUrl": "",
//    //                        "uid": result!.user.uid,
//    //                        "chatRoomCount": 0,
//    //                        "indexCount": 0
//    //                    ])
//    //
//    //                let storageRef = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
//    //                let storageProfileRef = storageRef.child("profile").child(result!.user.uid)
//    //
//    //                let metaData = StorageMetadata()
//    //                metaData.contentType = "image/jpg"
//    //                storageProfileRef.putData(imageData, metadata: metaData, completion: {
//    //                    (storageMetaData, error) in
//    //                    if error != nil{
//    //                        return
//    //                    }
//    //                    storageProfileRef.downloadURL(completion: {(url, error) in
//    //                        if let metaImageUrl = url?.absoluteString{
//    //
//    //                            db.collection("users").document(result!.user.uid).updateData([
//    //                                "profileImageUrl": metaImageUrl
//    //                            ])
//    //                        }
//    //                    })
//    //                })
//    //                Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
//    //                    if error != nil {
//    //                    }
//    //                    else {
//    //                        UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
//    //                        let controller = self.storyboard?.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
//    //                        controller.modalPresentationStyle = .fullScreen
//    //                        self.present(controller, animated: true, completion: nil)
//    //                    }
//    //                }
//    ////                After user signs up, clear userdefaults to make next sign up clean
//    //                UserDefaults.standard.removeObject(forKey: "phone")
//    //                UserDefaults.standard.removeObject(forKey: "email")
//    //                UserDefaults.standard.removeObject(forKey: "username")
//    //                UserDefaults.standard.removeObject(forKey: "password")
//    //                UserDefaults.standard.removeObject(forKey: "firstname")
//    //                UserDefaults.standard.removeObject(forKey: "lastname")
//    //                UserDefaults.standard.removeObject(forKey: "pronouns")
//    //                UserDefaults.standard.removeObject(forKey: "birthday")
//    //                UserDefaults.standard.removeObject(forKey: "major")
//    //                UserDefaults.standard.removeObject(forKey: "college")
//    //                UserDefaults.standard.removeObject(forKey: "classyear")
//    //                UserDefaults.standard.removeObject(forKey: "position")
//    //                UserDefaults.standard.removeObject(forKey: "location1")
//    //                UserDefaults.standard.removeObject(forKey: "location2")
//    //                UserDefaults.standard.removeObject(forKey: "location3")
//    //                UserDefaults.standard.removeObject(forKey: "interests")
//    //                }
//    //            }
//    
//    @IBAction func backButtonTapped(_ sender: Any) {
//        let controller = storyboard?.instantiateViewController(identifier: "interestInfoViewController") as! InterestInfoViewController
//        controller.modalTransitionStyle = .crossDissolve
//        controller.modalPresentationStyle = .fullScreen
//        present(controller, animated: true, completion: nil)
//    }
//    
//    func transitionToHome() {
//        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
//        
//        view.window?.rootViewController = homeViewController
//        view.window?.makeKeyAndVisible()
//    }
//    
//}
