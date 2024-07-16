
import Photos
import PhotosUI
import BSImagePicker
import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

class ProfilePictureViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    @IBOutlet weak var profilePicture: UIImageView!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    
    var image: UIImage? = nil
    private let storage = Storage.storage().reference()
    let imagePicker = UIImagePickerController()
    let uid = Auth.auth().currentUser!.uid
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorLabel.isHidden = true
        profilePicture.widthAnchor.constraint(equalToConstant: 210).isActive = true
        profilePicture.layer.cornerRadius = nextButton.frame.size.width/2
        profilePicture.layer.masksToBounds = true
        profilePicture.layer.borderWidth = 1
        profilePicture.layer.borderColor = CGColor(red: (0), green: (0), blue: (0), alpha: 1)
        
        nextButton.widthAnchor.constraint(equalToConstant: 50).isActive = true
        nextButton.layer.cornerRadius = nextButton.frame.size.width/2
        nextButton.layer.masksToBounds = true
        nextButton.tintColor = UIColor.white
        nextButton.titleLabel!.textColor = UIColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        nextButton.layer.borderWidth = 1
        nextButton.layer.borderColor = CGColor(red: CGFloat(1), green: CGFloat(0.353), blue: CGFloat(0.373), alpha: CGFloat(1.000))
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePictureViewController.imageTapped(gesture:)))
        profilePicture.addGestureRecognizer(tapGesture)
        profilePicture.isUserInteractionEnabled = true
        profilePicture.layer.borderWidth = 1
        profilePicture.layer.borderColor = UIColor.black.cgColor
        profilePicture.layer.cornerRadius = profilePicture.frame.height/2
        profilePicture.layer.masksToBounds = true
        profilePicture.clipsToBounds = true
        
        //Picking profile photo
        imagePicker.delegate = self
        imagePicker.allowsEditing = true

        setUpElements()
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    @objc func imageTapped(gesture: UIGestureRecognizer) {
        // if the tapped view is a UIImageView then set it to imageview
        if (gesture.view as? UIImageView) != nil {
            print("Image Tapped")
            
            let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
            
            alert.addAction(UIAlertAction(title: "Photo Gallery", style: .default, handler: { [weak self] (button) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.imagePicker.sourceType = .photoLibrary
                strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] (button) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.imagePicker.sourceType = .camera
                strongSelf.present(strongSelf.imagePicker, animated: true, completion: nil)
            }))
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            
            present(alert, animated: true, completion: nil)
        }
        
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info:
                               [UIImagePickerController.InfoKey: Any]){
        if let imageSelected = info[UIImagePickerController.InfoKey.editedImage] as? UIImage{
            image = cropToBounds(image: imageSelected, width: imageSelected.size.width, height: imageSelected.size.height)
            profilePicture.image = imageSelected
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
    func cropToBounds(image: UIImage, width: Double, height: Double) -> UIImage {

            let cgimage = image.cgImage!
            let contextImage: UIImage = UIImage(cgImage: cgimage)
            let contextSize: CGSize = contextImage.size
            var posX: CGFloat = 0.0
            var posY: CGFloat = 0.0
            var cgwidth: CGFloat = CGFloat(width)
            var cgheight: CGFloat = CGFloat(height)

            // See what size is longer and create the center off of that
            if contextSize.width > contextSize.height {
                posX = ((contextSize.width - contextSize.height) / 2)
                posY = 0
                cgwidth = contextSize.height
                cgheight = contextSize.height
            } else {
                posX = 0
                posY = ((contextSize.height - contextSize.width) / 2)
                cgwidth = contextSize.width
                cgheight = contextSize.width
            }

            let rect: CGRect = CGRect(x: posX, y: posY, width: cgwidth, height: cgheight)

            // Create bitmap image from context using the rect
            let imageRef: CGImage = cgimage.cropping(to: rect)!

            // Create a new image based on the imageRef and rotate back to the original orientation
            let image: UIImage = UIImage(cgImage: imageRef, scale: image.scale, orientation: image.imageOrientation)

            return image
        }

    
    @IBAction func didTapNextButton(){
        let phone = UserDefaults.standard.string(forKey: "phone")!
        let email = UserDefaults.standard.string(forKey: "email")!
        let username = UserDefaults.standard.string(forKey: "username")!
        let firstname = UserDefaults.standard.string(forKey: "firstname")!
        let lastname = UserDefaults.standard.string(forKey: "lastname")!
        let gender = UserDefaults.standard.string(forKey: "gender")!
        let birthday = UserDefaults.standard.string(forKey: "birthday")!
        let major = UserDefaults.standard.string(forKey: "major")!
        let college = UserDefaults.standard.string(forKey: "college")!
        let classYear = UserDefaults.standard.string(forKey: "classyear")!
        let company = ""
        let position = ""
        let interests = UserDefaults.standard.stringArray(forKey: "interests") ?? [String]()
        
        guard let imageSelected = image else{
            errorLabel.isHidden = false
            errorLabel.text = "Please select a profile picture"
            print("Avatar is nil")
            return
        }
        
        guard let imageData = imageSelected.jpegData(compressionQuality: 0.4) else{
            errorLabel.isHidden = false
            errorLabel.text = "Please select a profile picture"
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(uid).setData([
            "firstName": firstname,
            "lastName": lastname,
            "phone": phone,
            "email": email,
            "username": username,
            "gender": gender,
            "birthday": birthday,
            "interests": interests,
            "major": major,
            "college": college,
            "position": position,
            "company": company,
            "classYear": classYear,
            "profileImageUrl": "",
            "uid": uid,
            "chatRoomCount": 0,
            "indexCount": 0
        ])
        
        let storageRef = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
        let storageProfileRef = storageRef.child("profile").child(uid)
        
        let metaData = StorageMetadata()
        metaData.contentType = "image/jpg"
        storageProfileRef.putData(imageData, metadata: metaData, completion: {
            (storageMetaData, error) in
            if error != nil{
                return
            }
            storageProfileRef.downloadURL(completion: { [weak self] (url, error) in
                guard let strongSelf = self else {
                    return
                }
                if let metaImageUrl = url?.absoluteString{
                    
                    db.collection("users").document(strongSelf.uid).updateData([
                        "profileImageUrl": metaImageUrl
                    ])
                }
            })
        })
        UserDefaults.standard.removeObject(forKey: "phone")
        UserDefaults.standard.removeObject(forKey: "email")
        UserDefaults.standard.removeObject(forKey: "username")
        UserDefaults.standard.removeObject(forKey: "password")
        UserDefaults.standard.removeObject(forKey: "firstname")
        UserDefaults.standard.removeObject(forKey: "lastname")
        UserDefaults.standard.removeObject(forKey: "pronouns")
        UserDefaults.standard.removeObject(forKey: "gender")
        UserDefaults.standard.removeObject(forKey: "birthday")
        UserDefaults.standard.removeObject(forKey: "major")
        UserDefaults.standard.removeObject(forKey: "college")
        UserDefaults.standard.removeObject(forKey: "classyear")
        UserDefaults.standard.removeObject(forKey: "company")
        UserDefaults.standard.removeObject(forKey: "position")
        
        UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
        let controller = storyboard?.instantiateViewController(identifier: "HomeViewController") as! HomeViewController
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func backButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "majorViewController") as! MajorViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    func transitionToHome() {
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
}
