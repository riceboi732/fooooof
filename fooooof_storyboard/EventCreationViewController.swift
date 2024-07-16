//
//  EventCreationViewController.swift
//  fooooof_storyboard
//
//  Created by Victor Huang on 4/25/23.
//

import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore
import FirebaseStorage
import FirebaseDatabase

class EventCreationViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate  {
    
    @IBOutlet weak var eventTitle: UITextField!
    @IBOutlet weak var eventContent: UITextView!
    @IBOutlet weak var eventDatetime: UITextField!
    @IBOutlet weak var eventLocation: UITextField!
    @IBOutlet weak var eventPicture: UIImageView!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var backButton: UIButton!
    
    var image: UIImage? = nil
    private let storage = Storage.storage().reference()
    let imagePicker = UIImagePickerController()
    let uid = Auth.auth().currentUser!.uid
    private let db = Firestore.firestore()
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ProfilePictureViewController.imageTapped(gesture:)))
        eventPicture.addGestureRecognizer(tapGesture)
        eventPicture.isUserInteractionEnabled = true
        eventPicture.layer.borderWidth = 1
        eventPicture.layer.borderColor = UIColor.black.cgColor
        eventPicture.layer.cornerRadius = eventPicture.frame.height/2
        eventPicture.layer.masksToBounds = true
        eventPicture.clipsToBounds = true
        
        //Picking profile photo
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        //setUpElements() --> DO LATER!


    }
    
//    func setUpElements() {
//        errorLabel.isHidden = true
//    } --> DO LATER
    
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
            eventPicture.image = imageSelected
            self.image = imageSelected
        }
        
        picker.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func backButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "loginPhoneViewController") as! LoginPhoneViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any){
        print("save button tapped")
        let eventTitle = eventTitle.text
        let eventContent = eventContent.text
        let eventDatetime = eventDatetime.text
        let eventLocation = eventLocation.text
        
        guard let eventId = createEventId() else {
          return
      }
        
        if let imageData = self.image?.pngData() {
            let fileName = "event_photo_" + eventId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //Upload image to firebase database
            uploadEventPhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //Upload image to firebase firestore
                    print("Uploaded Event Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    if let metaImageUrl = url.absoluteString{
                        
                        self?.db.collection("events").document(eventId).setData([
                            "eventTitle": eventTitle ?? "",
                            "eventContent": eventContent ?? "",
                            "eventDatetime": eventDatetime ?? "",
                            "eventLocation": eventLocation ?? "",
                            "imageUrl": metaImageUrl
                        ], merge: true)
                    }
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        }
    }
    
    private func createEventId() -> String? {
        //date, otherUid, senderUid, randomInt
        
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifier = "\(uid)_\(dateString)"
        
        print("Created event id: \(newIdentifier)")
        
        return newIdentifier
    }
    
    //upload image for an event
    public func uploadEventPhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        let storage = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
        storage.child("event_images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageError.unknown))
                return
            }
            
            storage.child("event_images/\(fileName)").downloadURL(completion: { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageError.unknown))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returned: \(urlString)")
                completion(.success(urlString))
            })
        })
    }
}
