import UIKit
import TTGTagCollectionView
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

class EditProfileInterestsViewController: UIViewController, TTGTextTagCollectionViewDelegate {
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var saveButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    private var selections = [String]()
    
    let collectionView = TTGTextTagCollectionView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView.alignment = .center
        collectionView.delegate = self
        
        view.addSubview(collectionView)
        
        let config = TTGTextTagConfig()
        config.backgroundColor = .systemBlue
        config.textColor = .white
        config.borderColor = .systemOrange
        config.borderWidth = 1
        
        collectionView.addTags(["Reading","Anime","Manga","Working Out", "Music", "Sports","Travel","Poker","Beer","Hiking","Golf","Squash", "Skiing","Snowboarding","Creative Writing", "Dating"], with: config)
        setUpElements()
    }
    
    func setUpElements() {
        errorLabel.isHidden = true
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = CGRect(x: 0, y: 200, width: view.frame.size.width, height: 300)
    }
    
    func textTagCollectionView(_ textTagCollectionView: TTGTextTagCollectionView!, didTapTag tagText: String!, at index: UInt, selected: Bool, tagConfig config: TTGTextTagConfig!) {
        selections.append(tagText)
    }
    
    @IBAction func saveButtonTapped(_ sender: Any) {
        if selections.isEmpty{
            errorLabel.isHidden = false
            errorLabel.text = "Please enter information in all fields"
        }
        else{
            errorLabel.isHidden = true
            guard let userUid = Auth.auth().currentUser?.uid else { return }
            let db = Firestore.firestore()
            db.collection("users").document(userUid).updateData([
                "interests": selections
            ])
            let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
            controller.modalTransitionStyle = .crossDissolve
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
        }
    }
    
    @IBAction func cancelButtonTapped(_ sender: Any) {
        let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    

}
