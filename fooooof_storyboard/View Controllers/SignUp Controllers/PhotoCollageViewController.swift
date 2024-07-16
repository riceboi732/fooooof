////
////  PhotoCollageViewController.swift
////  fooooof_storyboard
////
////  Created by Victor Huang on 9/14/22.
////
//
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
//class PhotoCollageViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
//
//    @IBOutlet weak var photoCollage1: UIImageView!
//    @IBOutlet weak var photoCollage2: UIImageView!
//    @IBOutlet weak var photoCollage3: UIImageView!
//    @IBOutlet weak var photoCollage4: UIImageView!
//    @IBOutlet weak var nextButton: UIButton!
//    @IBOutlet weak var backButton: UIButton!
//
//    var imagePicker = UIImagePickerController()
//    var selectedView: UIView!
//
//    private let storage = Storage.storage().reference()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        photoCollage1.isUserInteractionEnabled = true
//        photoCollage1.layer.borderWidth = 1
//        photoCollage1.layer.masksToBounds = false
//        photoCollage1.layer.borderColor = UIColor.black.cgColor
//        photoCollage1.clipsToBounds = true
//
//        photoCollage2.isUserInteractionEnabled = true
//        photoCollage2.layer.borderWidth = 1
//        photoCollage2.layer.masksToBounds = false
//        photoCollage2.layer.borderColor = UIColor.black.cgColor
//        photoCollage2.clipsToBounds = true
//
//        photoCollage3.isUserInteractionEnabled = true
//        photoCollage3.layer.borderWidth = 1
//        photoCollage3.layer.masksToBounds = false
//        photoCollage3.layer.borderColor = UIColor.black.cgColor
//        photoCollage3.clipsToBounds = true
//
//        photoCollage4.isUserInteractionEnabled = true
//        photoCollage4.layer.borderWidth = 1
//        photoCollage4.layer.masksToBounds = false
//        photoCollage4.layer.borderColor = UIColor.black.cgColor
//        photoCollage4.clipsToBounds = true
//
//        //Picking profile photo
//        imagePicker.delegate = self
//        imagePicker.allowsEditing = true
//
//        [photoCollage1,photoCollage2,photoCollage3,photoCollage4].forEach {
//            $0?.isUserInteractionEnabled = true
//            $0?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseImage)))
//        }
//
//    }
//
//    @objc func chooseImage(_ gesture: UITapGestureRecognizer) {
//        if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
//            selectedView = gesture.view
//            present(imagePicker, animated: true)
//        }
//    }
//
//    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//        (selectedView as? UIImageView)?.image = info[.originalImage] as? UIImage
//        dismiss(animated: true)
//    }
//
//    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//        dismiss(animated: true)
//    }
//
//    @IBAction func skipButtonPressed(){
//        let controller = storyboard?.instantiateViewController(identifier: "interestInfoViewController") as! InterestInfoViewController
//        controller.modalPresentationStyle = .fullScreen
//        present(controller, animated: true, completion: nil)
//    }
//
//    @IBAction func nextButtonPressed(){
//        let email = UserDefaults.standard.string(forKey: "email")!
//        let password = UserDefaults.standard.string(forKey: "password")!
//        guard let imageSelected = self.image else{
//            print("Avatar is nil")
//            return
//        }
//
//        guard let imageData = imageSelected.jpegData(compressionQuality: 0.4) else{
//            return
//        }
//
//        Auth.auth().createUser(withEmail: email, password: password) { result, error in
//                if error != nil {
//                    return
//                }
//            else {
//                    let db = Firestore.firestore()
//                    db.collection("users").document(result!.user.uid).setData([
//                        "profileImageUrl": "",
//                        "uid": result!.user.uid,
//                    ])
//
//                let storageRef = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
//                let storageProfileRef = storageRef.child("profile").child(result!.user.uid)
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
//                            db.collection("users").document(result!.user.uid).updateData([
//                                "profileImageUrl": metaImageUrl
//                            ])
//                        }
//                    })
//                })
//                Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
//                    if error != nil {
//                    }
//                    else {
//                        UserDefaults.standard.set(true, forKey: "isUserLoggedIn")
//                        let controller = self.storyboard?.instantiateViewController(identifier: "photoCollageViewController") as! PhotoCollageViewController
//                        controller.modalPresentationStyle = .fullScreen
//                        self.present(controller, animated: true, completion: nil)
//                    }
//                }
//
//                }
//            }
//
//
//    }
//}
//
//@IBOutlet weak var imageView1: UIImageView!
//@IBOutlet weak var imageView2: UIImageView!
//
//var imagePicker = UIImagePickerController()
//var selectedView: UIView!
//
//override func viewDidLoad() {
//    super.viewDidLoad()
//
//    imagePicker.delegate = self
//    imagePicker.sourceType = .savedPhotosAlbum
//    imagePicker.allowsEditing = false
//
//    [imageView1,imageView2].forEach {
//        $0?.isUserInteractionEnabled = true
//        $0?.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(chooseImage)))
//    }
//}
//
//@objc func chooseImage(_ gesture: UITapGestureRecognizer) {
//    if UIImagePickerController.isSourceTypeAvailable(.savedPhotosAlbum) {
//        selectedView = gesture.view
//        present(imagePicker, animated: true)
//    }
//}
//func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
//    (selectedView as? UIImageView)?.image = info[.originalImage] as? UIImage
//    dismiss(animated: true)
//}
//
//func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
//    dismiss(animated: true)
//}
//}
