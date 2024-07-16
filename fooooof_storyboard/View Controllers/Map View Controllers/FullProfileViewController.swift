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
import SDWebImage

let fullProfileNotificationKey = "com.fooooof.fullProfileUpdate"

class FullProfileViewController: UIViewController, UITextFieldDelegate, TTGTextTagCollectionViewDelegate{
    @IBOutlet var backButton: UIButton!
    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    @IBOutlet var connectButton: UIButton!
    @IBOutlet var schoolLabel: UILabel!
    @IBOutlet var majorLabel: UILabel!
    @IBOutlet var professionalLabel: UILabel!
    @IBOutlet var profileImageView: UIImageView!
    @IBOutlet weak var blockButton: UIButton!
    @IBOutlet weak var greyButton: UIButton!
    @IBOutlet weak var messageButton: UIButton!
    @IBOutlet weak var unblockButton: UIButton!
    
    
    
    var selectedFirstName: String = "No First Name"
    var selectedLastName: String = "No Last Name"
    var selectedUsername: String = "No Username"
    var selectedProfileImageUrl: String = ""
    var selectedUid = ""
    var selectedMajor = ""
    var selectedCollege = ""
    var selectedClassYear = ""
    var selectedCompany = ""
    var selectedPositionAtCompany = ""
    let pfpURLs = (UserDefaults.standard.value(forKey: "commonFriendsPFP") as? String ?? "no mutual connections").components(separatedBy: " ")
    
    var myFirstName = "No First Name"
    let updated = Notification.Name(rawValue: fullProfileNotificationKey)
    var listener : ListenerRegistration? = nil
    var firstTime = true
    var buzzIndicator = 1
    let selfUid = Auth.auth().currentUser!.uid
    private let db = Firestore.firestore()
    let collectionView = TTGTextTagCollectionView()
    var trayDownOffset: CGFloat!
    var trayUp: CGPoint!
    var trayDown: CGPoint!
    
    private var conversations = [Conversation]()
    var userIsFriend = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        userIsFriend = false
        print("The selected uid is \(selectedUid)")
        if (selectedUid == "") {
            print("The selected uid is \(selectedUid)")
        } else {
            print("The selected valid uid is \(selectedUid)")
            fetchUserData()
        }
        //        addGesture()
        trayDownOffset = 500
        trayUp = view.center
        trayDown = CGPoint(x: view.center.x ,y: view.center.y + trayDownOffset)
        profileImageView.layer.cornerRadius = profileImageView.frame.size.width/2
        profileImageView.layer.masksToBounds = true
        connectButton.layer.cornerRadius = connectButton.frame.size.height/2
        connectButton.layer.masksToBounds = true
        greyButton.layer.cornerRadius = connectButton.frame.size.height/2
        greyButton.layer.masksToBounds = true
        messageButton.layer.cornerRadius = connectButton.frame.size.height/2
        messageButton.layer.masksToBounds = true
        unblockButton.layer.cornerRadius = connectButton.frame.size.height/2
        unblockButton.layer.masksToBounds = true
        blockButton.setTitle("", for: .normal)
        if (selectedUid == selfUid) {
            hideFriendButton()
        } else {
            isFriend()
        }
        startListeningForConversations()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        collectionView.frame = CGRect(x: 0, y: 300, width: view.frame.size.width, height: 150)
    }
    
    func hideFriendButton() {
        connectButton.alpha = 0
        greyButton.alpha = 0
    }
    
    func isFriend() {
        let selfUID = selfUid
        let currentUserDocRef =  db.collection("users").document(selfUID);
        currentUserDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                let friendDocRef =  currentUserDocRef.collection("firstDegreeFriends").document(strongSelf.selectedUid);
                friendDocRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        strongSelf.addAlreadyFriendUIFunction(text: "Message")
                        strongSelf.userIsFriend = true
                    } else {
                        let pendingDocRef =  currentUserDocRef.collection("sentRequests").document(strongSelf.selectedUid);
                        pendingDocRef.getDocument { (document1, error) in
                            if let document1 = document1, document1.exists {
                                strongSelf.addPendingUIFunction(text: "Pending")
                            } else {
                                strongSelf.addNotFriendFunction()
                            }
                        }
                    }
                }
            } else {
                print("Cannot get database for self.")
            }
        }
    }
    
    func addAlreadyFriendUIFunction(text: String) {
        print("message")
        messageButton.alpha = 1
        //show greybutton
        //        self.addFriendButton.tintColor = UIColor.lightGray
        //        self.addFriendButton.backgroundColor = UIColor.lightGray
        connectButton.alpha = 0
        greyButton.alpha = 0
        messageButton.setTitle(text, for: .normal)
    }
    
    @IBAction func messageButtonTapped(_ sender: Any) {
        let currentConversations = conversations
        
        if let targetConversation = currentConversations.first(where: {$0.otherUserUid == selectedUid
        }) {
            let vc = ChatViewController(with: targetConversation.otherUserUid, id: targetConversation.id)
            vc.isNewConversation = false
            vc.title = targetConversation.name
            let navigationController = UINavigationController(rootViewController: vc)
            navigationController.modalPresentationStyle = .fullScreen
            present(navigationController, animated: true)
        } else {
            createNewConversation(name: "\(selectedFirstName) \(selectedLastName)", uid: selectedUid)
        }
    }
    
    private func startListeningForConversations() {
        guard let uid = UserDefaults.standard.value(forKey: "selfUid") as? String else  {
            return
        }
        getAllConversations(for: uid, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got conversation models")
                guard !conversations.isEmpty else {
                    return
                }
                self?.conversations = conversations
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        })
    }
    
    func getAllConversations(for uid: String, completion: @escaping (Result<[Conversation], Error>) -> Void) {
        db.collection("users").document(uid).collection("conversations").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching conversation documents: \(error!)")
                return
            }
            var conversations: [Conversation] = []
            for document in documents {
                let dictionary = document.data()
                guard let conversationId = dictionary["id"] as? String,
                      let name = dictionary["name"] as? String,
                      let otherUserUid = dictionary["other_user_uid"] as? String,
                      let latestMessage = dictionary["latest_message"] as? [String: Any],
                      let date = latestMessage["date"] as? String,
                      let message = latestMessage["message"] as? String,
                      let isRead = latestMessage["is_read"] as? String else {
                    return
                }
                
                let latestMessageObject = LatestMessage(date: date, text: message, isRead: isRead)
                //
                conversations.append(Conversation(id: conversationId, name: name, otherUserUid: otherUserUid, latestMessage: latestMessageObject))
            }
            completion(.success(conversations))
        }
    }
    
    private func createNewConversation(name: String, uid: String) {
        // check in database if conversation with these two users exists
        // if it does, reuse conversation id
        // otherwise use existing code
        
        conversationExists(with: uid, completion: { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            switch result {
            case .success(let conversationId):
                let vc = ChatViewController(with: uid, id: conversationId)
                vc.isNewConversation = false
                vc.title = name
                let navigationController = UINavigationController(rootViewController: vc)
                navigationController.modalPresentationStyle = .fullScreen
                strongSelf.present(navigationController, animated: true)
            case .failure(_):
                let vc = ChatViewController(with: uid, id: nil)
                vc.isNewConversation = true
                vc.title = name
                let navigationController = UINavigationController(rootViewController: vc)
                navigationController.modalPresentationStyle = .fullScreen
                strongSelf.present(navigationController, animated: true)
            }
        })
    }
    
    func conversationExists(with targetRecipientUid: String, completion: @escaping (Result<String, Error>) -> Void) {
        guard let senderUid = UserDefaults.standard.value(forKey: "selfUid") as? String else  {
            return
        }
        
        db.collection("users").document(targetRecipientUid).collection("conversations").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else {
                print("Error fetching conversation documents: \(error!)")
                return
            }
            for document in documents {
                let dictionary = document.data()
                guard let targetSenderUid = dictionary["other_user_uid"] as? String else {
                    return
                }
                if targetSenderUid == senderUid {
                    guard let id = dictionary["id"] as? String else {
                        let error = NSError(domain: "", code: 404, userInfo: [ NSLocalizedDescriptionKey: "failed to fetch conversation id"])
                        completion(.failure(error as Error))
                        return
                    }
                    completion(.success(id))
                    return
                }
            }
            let error = NSError(domain: "", code: 404, userInfo: [ NSLocalizedDescriptionKey: "failed to fetch conversation id"])
            completion(.failure(error as Error))
            return
        }
    }
    
    func addPendingUIFunction(text: String) {
        connectButton.alpha = 0
        greyButton.alpha = 1
        greyButton.setTitle(text, for: .normal)
    }
    
    func fetchUserData(){
        collectionView.alignment = .center
        collectionView.delegate = self
        view.addSubview(collectionView)
        let config = TTGTextTagConfig()
        config.backgroundColor = .systemBlue
        config.textColor = .white
        config.borderColor = .systemOrange
        config.borderWidth = 1
        Firestore.firestore().collection("users").document(selectedUid).getDocument { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                strongSelf.nameLabel.text = (dictionary["firstName"] as! String) + " " +  (dictionary["lastName"] as! String)
                strongSelf.usernameLabel.text = "@" + (dictionary["username"] as! String)
                strongSelf.schoolLabel.text = (dictionary["college"] as! String) + ", Class of " + (dictionary["classYear"] as! String)
                strongSelf.majorLabel.text = (dictionary["major"] as! String)
                if ((dictionary["position"] as! String != "") && (dictionary["company"] as! String != "")){
                    strongSelf.professionalLabel.text = (dictionary["position"] as? String ?? "") + " at " + (dictionary["company"] as? String ?? "")
                }
                else{
                    strongSelf.professionalLabel.text = ""
                }
                strongSelf.collectionView.addTags(dictionary["interests"] as? [String], with: config)
                
                strongSelf.profileImageView.loadFrom(URLAddress: (dictionary["profileImageUrl"] as! String))
                
                if strongSelf.pfpURLs.count == 2{
                    guard let mutualFriend1ImageURL = URL(string: strongSelf.pfpURLs[0] ) else { return }
                    URLSession.shared.dataTask(with: mutualFriend1ImageURL) { (data, response, error) in
                        guard let mutualFriend1ImageData = data else { return }
                        
                        DispatchQueue.main.async {
                            let mutualFriend1Image = UIImage(data: mutualFriend1ImageData)
                            let mutualFriend1ImageView = UIImageView(image: mutualFriend1Image!)
                            mutualFriend1ImageView.frame = CGRect(x: 20, y: 230, width: 30, height: 30)
                            mutualFriend1ImageView.layer.cornerRadius = mutualFriend1ImageView.frame.size.width/2
                            mutualFriend1ImageView.layer.masksToBounds = true
                            strongSelf.view.addSubview(mutualFriend1ImageView)
                        }
                    }.resume()
                    
                    let commonFriendsLabel = UILabel(frame: CGRect(x: 55, y: 230, width: 270, height: 30))
                    commonFriendsLabel.textAlignment = .center
                    commonFriendsLabel.text = UserDefaults.standard.value(forKey: "commonFriends") as? String
                    
                    strongSelf.view.addSubview(commonFriendsLabel)
                }
                
                else if strongSelf.pfpURLs.count == 3{
                    
                    guard let mutualFriend1ImageURL = URL(string: strongSelf.pfpURLs[0] ) else { return }
                    URLSession.shared.dataTask(with: mutualFriend1ImageURL) { (data, response, error) in
                        guard let mutualFriend1ImageData = data else { return }
                        
                        DispatchQueue.main.async {
                            let mutualFriend1Image = UIImage(data: mutualFriend1ImageData)
                            let mutualFriend1ImageView = UIImageView(image: mutualFriend1Image!)
                            mutualFriend1ImageView.frame = CGRect(x: 20, y: 230, width: 30, height: 30)
                            mutualFriend1ImageView.layer.cornerRadius = mutualFriend1ImageView.frame.size.width/2
                            mutualFriend1ImageView.layer.masksToBounds = true
                            strongSelf.view.addSubview(mutualFriend1ImageView)
                        }
                    }.resume()
                    
                    
                    guard let mutualFriend2ImageURL = URL(string: strongSelf.pfpURLs[1] ) else { return }
                    URLSession.shared.dataTask(with: mutualFriend2ImageURL) { (data, response, error) in
                        guard let mutualFriend2ImageData = data else { return }
                        
                        DispatchQueue.main.async {
                            let mutualFriend2Image = UIImage(data: mutualFriend2ImageData)
                            let mutualFriend2ImageView = UIImageView(image: mutualFriend2Image!)
                            mutualFriend2ImageView.frame = CGRect(x: 40, y: 230, width: 30, height: 30)
                            mutualFriend2ImageView.layer.cornerRadius = mutualFriend2ImageView.frame.size.width/2
                            mutualFriend2ImageView.layer.masksToBounds = true
                            strongSelf.view.addSubview(mutualFriend2ImageView)
                        }
                    }.resume()
                    
                    let commonFriendsLabel = UILabel(frame: CGRect(x: 75, y: 230, width: 240, height: 30))
                    commonFriendsLabel.textAlignment = .center
                    commonFriendsLabel.text = UserDefaults.standard.value(forKey: "commonFriends") as? String
                    
                    strongSelf.view.addSubview(commonFriendsLabel)
                }
                
                else if strongSelf.pfpURLs.count >= 4{
                    
                    guard let mutualFriend1ImageURL = URL(string: strongSelf.pfpURLs[0] ) else { return }
                    URLSession.shared.dataTask(with: mutualFriend1ImageURL) { (data, response, error) in
                        guard let mutualFriend1ImageData = data else { return }
                        
                        DispatchQueue.main.async {
                            let mutualFriend1Image = UIImage(data: mutualFriend1ImageData)
                            let mutualFriend1ImageView = UIImageView(image: mutualFriend1Image!)
                            mutualFriend1ImageView.frame = CGRect(x: 20, y: 230, width: 30, height: 30)
                            mutualFriend1ImageView.layer.cornerRadius = mutualFriend1ImageView.frame.size.width/2
                            mutualFriend1ImageView.layer.masksToBounds = true
                            strongSelf.view.addSubview(mutualFriend1ImageView)
                        }
                    }.resume()
                    
                    
                    guard let mutualFriend2ImageURL = URL(string: strongSelf.pfpURLs[1] ) else { return }
                    URLSession.shared.dataTask(with: mutualFriend2ImageURL) { (data, response, error) in
                        guard let mutualFriend2ImageData = data else { return }
                        
                        DispatchQueue.main.async {
                            let mutualFriend2Image = UIImage(data: mutualFriend2ImageData)
                            let mutualFriend2ImageView = UIImageView(image: mutualFriend2Image!)
                            mutualFriend2ImageView.frame = CGRect(x: 40, y: 230, width: 30, height: 30)
                            mutualFriend2ImageView.layer.cornerRadius = mutualFriend2ImageView.frame.size.width/2
                            mutualFriend2ImageView.layer.masksToBounds = true
                            strongSelf.view.addSubview(mutualFriend2ImageView)
                        }
                    }.resume()
                    
                    guard let mutualFriend3ImageURL = URL(string: strongSelf.pfpURLs[2] ) else { return }
                    URLSession.shared.dataTask(with: mutualFriend3ImageURL) { (data, response, error) in
                        guard let mutualFriend3ImageData = data else { return }
                        
                        DispatchQueue.main.async {
                            let mutualFriend3Image = UIImage(data: mutualFriend3ImageData)
                            let mutualFriend3ImageView = UIImageView(image: mutualFriend3Image!)
                            mutualFriend3ImageView.frame = CGRect(x: 60, y: 230, width: 30, height: 30)
                            mutualFriend3ImageView.layer.cornerRadius = mutualFriend3ImageView.frame.size.width/2
                            mutualFriend3ImageView.layer.masksToBounds = true
                            strongSelf.view.addSubview(mutualFriend3ImageView)
                            
                        }
                    }.resume()
                    
                    let commonFriendsLabel = UILabel(frame: CGRect(x: 95, y: 230, width: 220, height: 30))
                    commonFriendsLabel.textAlignment = .center
                    commonFriendsLabel.text = UserDefaults.standard.value(forKey: "commonFriends") as? String
                    
                    strongSelf.view.addSubview(commonFriendsLabel)
                }
                
                
                
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getUserFirstName() {
        db.collection("users").document(selfUid).getDocument() { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if snapshot?.get("firstName") == nil {
                print(error ?? "fuck my life")
            } else {
                strongSelf.myFirstName = snapshot?.get("firstName") as! String
            }
        }
    }
    
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(FullProfileViewController.updateFullProfile(notification:)), name: updated, object: nil)
    }
    
    @objc func updateFullProfile(notification: NSNotification) {
        if let firstName = notification.userInfo?["firstName"] as? String {
            selectedFirstName = firstName
        }
        if let lastName = notification.userInfo?["lastName"] as? String {
            selectedLastName = lastName
        }
        if let username = notification.userInfo?["username"] as? String {
            selectedUsername = username
        }
        if let profileImageUrl = notification.userInfo?["profileImageUrl"] as? String {
            selectedProfileImageUrl = profileImageUrl
        }
        if let uid = notification.userInfo?["uid"] as? String {
            selectedUid = uid
        }
        if let major = notification.userInfo?["major"] as? String {
            selectedMajor = major
        }
        if let college = notification.userInfo?["college"] as? String {
            selectedCollege = college
        }
        if let classYear = notification.userInfo?["classYear"] as? String {
            selectedClassYear = classYear
        }
        if let company = notification.userInfo?["company"] as? String {
            selectedCompany = company
        }
        if let positionAtCompany = notification.userInfo?["position"] as? String {
            selectedPositionAtCompany = positionAtCompany
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if listener != nil {
            listener?.remove()
        }
    }
    
    @IBAction func didTapBackButton(){
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    @IBAction func addFriend(_ sender: Any) {
        addPendingUIFunction(text: "pending")
        addUserOneInfoToUserTwo(A: selfUid, B: selectedUid);
    }
    
    func addUserOneInfoToUserTwo(A: String, B: String) {
        let currentUserDocRef =  db.collection("users").document(A);
        let requestedDocRef =  db.collection("users").document(B);
        currentUserDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                currentUserDocRef.collection("sentRequests").document(B).setData(["uid":B])
            } else {
                print("No user A document available.")
            }
        }
        requestedDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                requestedDocRef.collection("receivedRequests").document(A).setData(["uid":A])
            } else {
                print( "No user B document available.")
            }
        }
    }
    
    func addNotFriendFunction() {
        print("notFriends")
        greyButton.alpha = 0
        print("notFriends 1")
        //check if currentUser blocked by selectedUid
        db.collection("blocked").document(selectedUid).getDocument { [weak self] (snapshot, error) in
            print("notFriends 2")
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                print("notFriends 3")
                let blocked = dictionary[self?.selfUid ?? ""] as? Bool
                print("notFriends 4")
                if blocked == nil {
                    print("This user is not blocked")
                    //Only show connect button if not blocked
                    //Update recipient user conversation entry
                    self?.connectButton.alpha = 1
                } else if blocked == true {
                    print("This user is blocked")
                    self?.connectButton.alpha = 0
                } else {
                    print("This user was blocked but now isn't blocked")
                    //Only show connect button if not blocked
                    //Update recipient user conversation entry
                    self?.connectButton.alpha = 1
                }
            } else {
                self?.connectButton.alpha = 1
            }
        }
        
        //check if selectedUid blocked by currentUser
        db.collection("blocked").document(selfUid).getDocument { [weak self] (snapshot, error) in
            print("notFriends 2")
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                print("notFriends 3")
                let blocked = dictionary[self?.selectedUid ?? ""] as? Bool
                print("notFriends 4")
                if blocked == nil {
                    print("This user is not blocked")
                    //Only show connect button if not blocked
                    //Update recipient user conversation entry
                    self?.connectButton.alpha = 1
                } else if blocked == true {
                    print("This user is blocked")
                    self?.connectButton.alpha = 0
                    self?.unblockButton.alpha = 1
                } else {
                    print("This user was blocked but now isn't blocked")
                    //Only show connect button if not blocked
                    //Update recipient user conversation entry
                    self?.connectButton.alpha = 1
                }
            } else {
                self?.connectButton.alpha = 1
            }
        }
    }
    
    @IBAction func unblock(_ sender: Any) {
        // 1) delete from block list mutually / change block to false in database
        deleteFromBlockList(blockerUid: selfUid, blockedUid: selectedUid)
        // 2) make fullprofile button "connect"
        unblockButton.alpha = 0
        connectButton.alpha = 1
    }
    
    func deleteFromBlockList(blockerUid: String, blockedUid: String) {
        let docData: [String: Any] = [
            blockedUid: false
        ]
        db.collection("blocked").document(blockerUid).setData(docData, merge: true) { err in
            if let err = err {
                print("Error deleting \(blockedUid) from blocked list: \(err)")
            } else {
                print("\(blockedUid) successfully unblocked!")
            }
        }
    }
    
    func goBack() {
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    @IBAction func presentInputActionSheet(_ sender: Any) {
        let actionSheet = UIAlertController(title: "Settings", message: "What would you like to do?", preferredStyle: .actionSheet)
        if userIsFriend {
            actionSheet.addAction(UIAlertAction(title: "Unfriend", style: .default, handler: { [weak self] _ in
                print("Unfriend user")
                Block.unfriendButtonPressed(selectedUid: self?.selectedUid ?? "", selfUid: self?.selfUid ?? "", db: self!.db) { completed in
                }
            }))
            actionSheet.addAction(UIAlertAction(title: "Block", style: .default, handler: { [weak self] _ in
                print("Block friend user")
                self?.blockCurrentFriendButtonPressed()
            }))
        } else {
            actionSheet.addAction(UIAlertAction(title: "Block", style: .default, handler: { [weak self] _ in
                print("Block nonfriend user")
                self?.blockNonFriendButtonPressed()
            }))
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
}

extension FullProfileViewController {
    // Will stop sharing second degree friend resources with each other on map, but still can chat & re-add
    
    func blockCurrentFriendButtonPressed(){
        // 1) Done: Add user to a block list
        Block.addToBlockList(blockerUid: selfUid, blockedUid: selectedUid, db: db)
        // 2) Done: Users see chat message from people they block
        // 3) Done: unfriend both sides (just call above functions)
        Block.unfriendButtonPressed(selectedUid: selectedUid, selfUid: selfUid, db: db) { completed in
        }
        unblockButton.alpha = 1
        connectButton.alpha = 0
        // 4) Done: Delete/hide from map
        // 5) Done: Blocker no longer receive friend request in the future, blocked cannot send friend request in the future
        // 6) Done: Make button in fullprofile "unblock"
        // 7) make sure they never show up in second degree list in full profiles
    }
    
    func blockNonFriendButtonPressed(){
        // 1) Done: Add user to a block list
        Block.addToBlockList(blockerUid: selfUid, blockedUid: selectedUid, db: db)
        unblockButton.alpha = 1
        connectButton.alpha = 0
        // 2) Done: cannot see chat message from blocked person
        // 3) Done: Delete/hide from map
        // 4) Done: Blocker no longer receive friend request in the future, blocked cannot send friend request in the future
        // 5) Done: Make button in fullprofile "unblock"
        // 6) make sure they never show up in second degree list in full profiles
    }
}
