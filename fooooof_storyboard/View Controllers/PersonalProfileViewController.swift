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
import FirebaseFunctions

class PersonalProfileViewController: UIViewController, TTGTextTagCollectionViewDelegate{
    @IBOutlet var backButton: UIButton!
    @IBOutlet weak var messagesViewButton: UIButton!
    @IBOutlet weak var personalProfileButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet var schoolLabel: UILabel!
    @IBOutlet weak var majorLabel: UILabel!
    @IBOutlet var professionalLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet var editButton: UIButton!
    @IBOutlet weak var connectionsButton: UIButton!
    @IBOutlet weak var previewButton: UIButton!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet var deleteButton: UIButton!
    
    
    let collectionView = TTGTextTagCollectionView()
    private let db = Firestore.firestore()
    let userId = Auth.auth().currentUser!.uid
    lazy var functions = Functions.functions()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        deleteButton.setTitle("", for: .normal)
        scrollView.contentSize = CGSizeMake(view.frame.width, view.frame.height+100)
        fetchUserData()
        editButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        previewButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 17)
        connectionsButton.contentHorizontalAlignment = .left;
        backButton.setTitle("", for: .normal)
        messagesViewButton.setTitle("", for: .normal)
        personalProfileButton.setTitle("", for: .normal)
        //red underline to preview button
        let lineView = UIView(frame: CGRectMake(0, previewButton.frame.size.height, previewButton.frame.size.width, 2))
        lineView.backgroundColor = UIColor(named: "fooooofRed")
        previewButton.addSubview(lineView)
        //shadow to edit & preview buttons
        editButton.layer.shadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.25).cgColor
        editButton.layer.shadowOffset = CGSize(width: 0.0, height: 2.0)
        editButton.layer.shadowOpacity = 0.5
        editButton.layer.shadowRadius = 0.5
        editButton.layer.masksToBounds = false
        editButton.layer.cornerRadius = 0
        previewButton.layer.masksToBounds = false
        previewButton.layer.cornerRadius = 0
        editButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 14)
        previewButton.titleLabel?.font = UIFont(name: "Inter-Bold", size: 14)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = CGRect(x: 0, y: 250, width: view.frame.size.width, height: 150)
    }
    
    
    @IBAction func transitionToMessages(_ sender: Any) {
        //        let vc = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.navigationController) as! UINavigationController
        //        view.window?.rootViewController = vc
        //        view.window?.makeKeyAndVisible()
        let vc = storyboard?.instantiateViewController(withIdentifier: "Messages1ViewController") as! Messages1ViewController
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func seeConnections(_ sender: Any) {
        print("trying to see connections")
        let vc = storyboard?.instantiateViewController(withIdentifier: "SearchUser") as! SearchUserViewController
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    @IBAction func presentInputActionSheet(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Settings", message: "What would you like to do?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Sign Out", style: .default, handler: { [weak self] _ in
            self?.logoutButtonPressed()
            print("sign out")
        }))
        actionSheet.addAction(UIAlertAction(title: "Deactivate Account", style: .default, handler: { [weak self] _ in
            //            self?.deactivateEmail()
            print("deactivate account")
            self?.deleteSelfPermanent()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    func fetchUserData() {
        collectionView.alignment = .center
        collectionView.delegate = self
        view.addSubview(collectionView)
        let config = TTGTextTagConfig()
        config.backgroundColor = .systemBlue
        config.textColor = .white
        config.borderColor = .systemOrange
        config.borderWidth = 1
        guard let userUid = Auth.auth().currentUser?.uid else { return }
        Firestore.firestore().collection("users").document(userUid).getDocument { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                strongSelf.nameLabel.text = (dictionary["firstName"] as! String) + " " +  (dictionary["lastName"] as! String)
                strongSelf.usernameLabel.text = "@" + (dictionary["username"] as! String)
                strongSelf.schoolLabel.text = (dictionary["college"] as! String) + " " + (dictionary["classYear"] as! String)
                strongSelf.majorLabel.text = (dictionary["major"] as! String)
                if ((dictionary["position"] as! String != "") && (dictionary["company"] as! String != "")){
                    strongSelf.professionalLabel.text = (dictionary["position"] as? String ?? "") + " at " + (dictionary["company"] as? String ?? "")
                }
                else{
                    strongSelf.professionalLabel.text = ""
                }
                strongSelf.profileImageView.loadFrom(URLAddress: (dictionary["profileImageUrl"] as! String))
                strongSelf.getNumConnections(uid: userUid)
                //                if (dictionary["numConnections"] != nil) {
                //                    print("number of connections: \(dictionary["numConnections"])")
                //                    if(dictionary["numConnections"] as! String == "1") {
                //                        self.connectionsButton.setTitle( (dictionary["numConnections"] as! String) + " Connection", for: .normal)
                //                    } else {
                //                        self.connectionsButton.setTitle( (dictionary["numConnections"] as! String) + " Connections", for: .normal)
                //                    }
                //                }else {
                //                    self.getNumConnections(uid: userUid)
                //                }
            }
        }
    }
    
    func getNumConnections(uid: String) {
        print("definitely calling getNumConnections")
        Firestore.firestore().collection("users").document(uid).collection("firstDegreeFriends").getDocuments { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            var str = ""
            if let v = snapshot?.count {
                str = "\(v)"
            }
            //            Firestore.firestore().collection("users").document(uid).setData(["numConnections": str], merge: true)
            if(str == "1") {
                strongSelf.connectionsButton.setTitle(  str + " Connection", for: .normal)
            } else {
                strongSelf.connectionsButton.setTitle(  str + " Connections", for: .normal)
            }
        }
        //        Firestore.firestore().collection("users").document(userUid).collection("firstDegreeFriends")
        //            .getDocuments { querySnapshot, err in
        //                if let err = err {
        //                    print ("Error getting documents: \(err)")
        //                } else {
        //                    let connections = querySnapshot?.count
        //                    self.connectionLabel.text = "Connections: \((connections)!)"
        //                }
        //            }
    }
    
    @IBAction func returnToHome(segue: UIStoryboardSegue){
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    private func logoutButtonPressed() {
        let auth = Auth.auth()
        do{
            try auth.signOut()
            UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
            let controller = storyboard?.instantiateViewController(identifier: "ViewController") as! ViewController
            controller.modalPresentationStyle = .fullScreen
            present(controller, animated: true, completion: nil)
            deleteToken()
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    private func deactivateEmail() {
        showNotification(title: "Deactivate", body: "To deactivate your account, please contact us at info@fooooof.com.", response: "Okay")
        
        //        let mailComposerVC = MFMailComposeViewController()
        //        mailComposerVC.mailComposeDelegate = self
        //        mailComposerVC.setToRecipients(["info@fooooof.com"])
        //        mailComposerVC.setSubject("Subject")
        //        mailComposerVC.setMessageBody("Body", isHTML: false)
        //        self.presentViewController(mailComposerVC, animated: true, completion: nil)
    }
    
    private func showNotification(title: String, body: String, response: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okayAction = UIAlertAction(title:response, style: .default) { (action) in
        }
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func editButtonPressed(){
        let controller = storyboard?.instantiateViewController(identifier: "editProfileViewController") as! EditProfileViewController
        controller.modalTransitionStyle = .crossDissolve
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    func deleteToken() {
        db.collection("users").document(userId).setData(["token" : ""],merge: true)
    }
    
    func deleteSelf() {
        // info@fooooof.com pop up notification to contact
        
        //first unfriend them from everyone. Then delete self' information. then deactivate from auth.
        
        // Later:
        // First check with their phone number that they're the user
        // Ideally delete account from everything, but for now keep the info and just hide their account on the map
        // When we have time in the future, do temporary & permanent delete
        // Add them to a global collection of deactivatedUsers, and for future map displays, check if their second degree friends are on the list, and delete that from the list
        // Log them out
        // Present with onboarding screen
    }
    
    func deleteSelfPermanent() {
        // First check with their phone number that they're the user
        // block all friends
        print("blockAllFriends")
        blockAllFriends() {[weak self] completed in
            // delete all info
            print("deleteAllInfo")
            self?.deleteAllInfo() {completed in
                // deactivate & log out of firebase account & present with onboarding screen
                if completed {
                    print("deactivateFirebaseAuth")
                    self?.deactivateFirebaseAuth()
                }
            }
        }
    }
    
    func deleteAllInfo(completion: @escaping (Bool) -> Void) {
        functions.httpsCallable("deleteObjectAndSubcollectionsAndFields").call(["uid": userId]) { result, error in
            if let error = error as NSError? {
                if error.domain == FunctionsErrorDomain {
                    let code = FunctionsErrorCode(rawValue: error.code)
                    let message = error.localizedDescription
                    let details = error.userInfo[FunctionsErrorDetailsKey]
                    print("Delete all info didn't work: \(String(describing: code)) \(message) \(String(describing: details))")
                }
                completion(false)
                // ...
            }
            //          if let data = result?.data as? [String: Any], let text = data["text"] as? String {
            //            self.resultField.text = text
            //          }
            if let data = result?.data as? String {
                print("\(data)")
            }
            completion(true)
        }
    }
    
    func deactivateFirebaseAuth() {
        let user = Auth.auth().currentUser
        user?.delete { [weak self] error in
            if let error = error {
                // An error happened.
                print("\(error)")
            } else {
                // Account deleted.
                UserDefaults.standard.set(false, forKey: "isUserLoggedIn")
                let controller = self?.storyboard?.instantiateViewController(identifier: "ViewController") as! ViewController
                controller.modalPresentationStyle = .fullScreen
                self?.present(controller, animated: true, completion: nil)
                self?.deleteToken()
            }
        }
    }
    
    func blockAllFriends(completion: @escaping (Bool) -> Void) {
        db.collection("users").document(userId).collection("firstDegreeFriends").getDocuments() { [weak self] (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
                completion(false)
            } else {
                for document in querySnapshot!.documents {
                    let selectedUid = document.documentID
                    Block.addToBlockList(blockerUid: self!.userId, blockedUid: selectedUid, db: self!.db)
                    Block.unfriendButtonPressed(selectedUid: selectedUid, selfUid: self!.userId, db: self!.db){ completed in
                    }
                }
                completion(true)
            }
        }
    }
}

extension UIImageView {
    func loadFrom(URLAddress: String) {
        guard let url = URL(string: URLAddress) else {
            return
        }
        
        sd_setImage(with: url)
        layer.cornerRadius = (frame.height) / 2.0
        layer.masksToBounds = true
        
        //        DispatchQueue.main.async { [weak self] in
        //            if let imageData = try? Data(contentsOf: url) {
        //                if let loadedImage = UIImage(data: imageData) {
        //                    self?.image = loadedImage
        //                }
        //            }
        //        }
    }
}
