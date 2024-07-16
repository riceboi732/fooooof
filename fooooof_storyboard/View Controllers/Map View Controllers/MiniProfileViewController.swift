import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox
import SDWebImage

let miniProfileNotificationKey = "com.fooooof.miniProfileUpdate"

class MiniProfileViewController: UIViewController{
    
    @IBOutlet weak var friendInfoText: UILabel!
    @IBOutlet weak var usernameText: UILabel!
    @IBOutlet weak var collegeText: UILabel!
    @IBOutlet weak var classYearText: UILabel!
    
    @IBOutlet weak var commonFriendsText: UITextView!
    @IBOutlet weak var profileImage: UIImageView!
    @IBOutlet weak var sendMessageButton: UIButton!
    var selectedFirstName: String = "No First Name"
    var selectedLastName: String = "No Last Name"
    var selectedUsername: String = ""
    var selectedProfileImageUrl: String = ""
    var selectedUid = ""
    var selectedMajor = ""
    var selectedCollege = ""
    var selectedClassYear = ""
    var selectedCompany = ""
    var selectedPositionAtCompany = ""
    var myFirstName = "No First Name"
    let updated = Notification.Name(rawValue: miniProfileNotificationKey)
    var listener : ListenerRegistration? = nil
    var firstTime = true
    var buzzIndicator = 1
    let userId = Auth.auth().currentUser!.uid
    var selfUsername = ""
    private let db = Firestore.firestore()
    private var conversations = [Conversation]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.makeCorner(withRadius: 10.0)
        print(userId + "mini profile userId")
        friendInfoText.text = selectedFirstName + selectedLastName
        usernameText.text = selectedUsername
        collegeText.text = selectedCollege
        classYearText.text = selectedClassYear
        createObservers()
        commonFriendsText.text = ""
        getUserFirstName()
        doubleTapProfilePic()
        snapShotListenerForBuzz()
        addGesture()
        startListeningForConversations()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func getUserFirstName() {
        db.collection("users").document(userId).getDocument() { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            if snapshot?.get("firstName") == nil {
                print(error ?? "fuck my life again")
            } else {
                strongSelf.myFirstName = snapshot?.get("firstName") as! String
            }
        }
    }
    
    func createObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(MiniProfileViewController.updateMiniProfile(notification:)), name: updated, object: nil)
    }
    
    @objc func updateMiniProfile(notification: NSNotification) {
        if let uid = notification.userInfo?["uid"] as? String {
            selectedUid = uid
        }
        
        if selectedUid == userId {
            if let profileImageUrl = notification.userInfo?["profileImageUrl"] as? String {
                selectedProfileImageUrl = profileImageUrl
            }
            dismiss(animated: true, completion:nil)
        } else {
            commonFriendsText.alpha = 1
            sendMessageButton.alpha = 1
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
            friendInfoText.text = "\(selectedFirstName) \(selectedLastName)"
            usernameText.text = "@\(selectedUsername)"
            collegeText.text = "\(selectedCollege)"
            classYearText.text = "Class of \(selectedClassYear)"
            addProfile(profileImageUrl: selectedProfileImageUrl)
            if let commonFriends = notification.userInfo?["commonFriends"] as? String {
                commonFriendsText.text = commonFriends
            }
        }
        
        
    }
    
    func addProfile(profileImageUrl: String) {
        guard let url = URL(string: profileImageUrl) else { return }
        profileImage.sd_setImage(with: url)
        profileImage.layer.cornerRadius = profileImage.frame.height / 2.0
        profileImage.layer.masksToBounds = true
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToFullProfile" {
            let controller = segue.destination as! FullProfileViewController
            controller.selectedFirstName = selectedFirstName
            controller.selectedUsername = selectedUsername
            controller.selectedLastName = selectedLastName
            controller.selectedUid = selectedUid
            controller.selectedMajor = selectedMajor
            controller.selectedCollege = selectedCollege
            controller.selectedClassYear = selectedClassYear
            controller.selectedCompany = selectedCompany
            controller.selectedPositionAtCompany = selectedPositionAtCompany
            controller.view.isUserInteractionEnabled = true
        }
    }
    
    func addGesture() {
        let gestureRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(gestureFired(_:)))
        gestureRecognizer.direction = .up
        gestureRecognizer.numberOfTouchesRequired = 1
        view.addGestureRecognizer(gestureRecognizer)
        view.isUserInteractionEnabled = true
    }
    
    @objc func gestureFired(_ gesture: UISwipeGestureRecognizer) {
        performSegue(withIdentifier: "ToFullProfile", sender: nil)
    }
    
    private func startListeningForConversations() {
        guard let uid = UserDefaults.standard.value(forKey: "selfUid") as? String else  {
            return
        }
        getAllConversations(for: uid, completion: { [weak self] result in
            switch result {
            case .success(let conversations):
                print("successfully got conversation models")
                self?.conversations = conversations
            case .failure(let error):
                print("failed to get convos: \(error)")
            }
        })
    }
    
    func doubleTapProfilePic() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(doubleTapped))
        tap.numberOfTapsRequired = 2
        profileImage.isUserInteractionEnabled = true
        view.isUserInteractionEnabled = true
        profileImage.addGestureRecognizer(tap)
    }
    
    
    @objc func doubleTapped() {
        if selectedUid != "" {
            checkChatRoomExistence(myUid: userId, friendUid: selectedUid, mymessage: "\(myFirstName) tickled \(selectedFirstName)") { [weak self] (userId, friendId, mymessage) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.updateChat(myUid: userId, friendUid: friendId, mymessage: mymessage) { error in
                    let friendProfile = strongSelf.db.collection("users").document(strongSelf.selectedUid)
                    friendProfile.getDocument() {(snapshot, error) in
                        if snapshot?.get("buzz") != nil{
                            if snapshot?.get("buzz") as! Int == 1{
                                friendProfile.setData(["buzz" : 0], merge: true)
                            } else {
                                friendProfile.setData(["buzz" : 1], merge: true)
                            }
                        }
                    }
                }
            }
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    func snapShotListenerForBuzz() {
        listener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
            guard let strongSelf = self else {
                return
            }
            switch (snapshot, error) {
                    case (.none, .none):
                        print("no data")
                    case (.none, .some(let error)):
                        print("some error \(error.localizedDescription)")
                    case (.some(_), _):
                        if strongSelf.firstTime == true {
                            strongSelf.buzzIndicator = 1
                            strongSelf.db.collection("users").document(strongSelf.userId).setData(["buzz" : 1], merge: true) { err in
                                strongSelf.firstTime = false
                            }
                        } else if snapshot?.get("buzz") == nil {
                            strongSelf.buzzIndicator = 1
                            strongSelf.db.collection("users").document(strongSelf.userId).setData(["buzz" : 1], merge: true) { err in
                                strongSelf.firstTime = false
                            }
                        } else {
                            if snapshot?.get("buzz") as! Int != strongSelf.buzzIndicator {
                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                strongSelf.buzzIndicator = snapshot?.get("buzz") as! Int
                            }
                        }
            }
        }
    }
    
    func onAppIndication(_ userId: String) {
        db.collection("users").document(userId).setData(["onApp":1],merge: true)
    }
    
    func offAppIndication(_ userId: String) {
        db.collection("users").document(userId).setData(["onApp":0],merge: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if listener != nil {
            listener?.remove()
        }
    }
    
    func checkChatRoomExistence(myUid: String, friendUid: String, mymessage: String, completion: @escaping (_ myUid: String, _ friendUid: String, _ mymessage: String) -> Void)->Void {
        let chatroom = db.collection("users").document(myUid).collection("chats").document(friendUid)
        chatroom.getDocument{ [weak self] (snapshot,error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error{
                print("\(error)")
            } else if snapshot!.get("messageCount") == nil {
                strongSelf.db.collection("users").document(myUid).getDocument() {(snapshot1, error) in
                    let indexCount = snapshot1?.get("indexCount") as! Int
                    strongSelf.db.collection("users").document(myUid).setData(["indexCount": indexCount + 1], merge: true)
                    chatroom.setData(["chatroomIndex": indexCount + 1], merge: true) { err in
                        strongSelf.initiateChatroom(myUid, friendUid, chatroom) { (chatRoom) in
                            completion(myUid, friendUid, mymessage)
                        }
                        strongSelf.db.collection("users").document(myUid).getDocument() { (snapshot1, error) in
                            let chatRoomCount = snapshot1?.get("chatRoomCount") as! Int + 1
                            strongSelf.db.collection("users").document(myUid).setData(["chatRoomCount" : chatRoomCount], merge: true)
                        }
                    }
                }
             } else {
                completion(myUid, friendUid, mymessage)
             }
        }
    }
    
    
    func creatMessageDocument(_ chatroom2 : DocumentReference,_ myUid: String, _ friendUid : String, _ sender : String, _ count : Int, _ mymessage : String, completion : @escaping ()->()){
        chatroom2.collection("messages").document(myUid+friendUid+"!"+String(count+1)).setData(["sender":sender, "message":mymessage, "index":count+1],merge: true) { err in
            completion()
        }
    }
    
    func updateChat(myUid: String, friendUid: String, mymessage: String, completion: @escaping (_ error: Error?) -> Void)->Void{
        let chatroom = db.collection("users").document(myUid).collection("chats").document(friendUid)
        chatroom.getDocument{ [weak self] (snapshot,error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error{
                print("\(error)")
                completion(error)
            } else {
                let count1 = snapshot?.get("messageCount") as! Int
                strongSelf.creatMessageDocument(chatroom, myUid, friendUid, "me", count1, mymessage) { () in
                    chatroom.setData(["lastMessage": mymessage, "sender": "me", "time": Date()], merge: true) { err in
                        chatroom.setData(["messageCount":count1+1], merge: true)
                    }
                    chatroom.getDocument() { (snapshot, error) in
                        strongSelf.db.collection("users").document(myUid).getDocument() { (snapshot1, error) in
                            var index = snapshot1?.get("indexCount") as! Int
                            if snapshot?.get("chatroomIndex") as! Int != index {
                                index = index + 1
                                chatroom.setData(["chatroomIndex" : index], merge: true)
                                strongSelf.db.collection("users").document(myUid).setData(["indexCount" : index], merge: true)
                            }
                        }
                    }
                }
                
            }
        }
    
        let chatroom2 = db.collection("users").document(friendUid).collection("chats").document(myUid)
        chatroom2.getDocument{ [weak self] (snapshot1,error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error{
                print("\(error)")
                completion(error)
            } else {
                var index1 = 0
                var count = 0
                if snapshot1!.get("messageCount") == nil {
                    chatroom2.setData(["chatroomIndex" : 0], merge: true)
                    strongSelf.initiateChatroom(friendUid, myUid, chatroom2) { (chatroom2) in
                    }
                    let chatPage = strongSelf.db.collection("users").document(friendUid)
                    chatPage.getDocument(){ (snapshot, error) in
                        if error != nil {
                            print("Error")
                        } else {
                            var count = snapshot?.get("chatRoomCount") as! Int
                            count = count + 1
                            strongSelf.db.collection("users").document(friendUid).setData(["chatRoomCount" : count],merge: true)
                        }
                    }
                } else {
                    count = snapshot1!.get("messageCount") as! Int
                    index1 = snapshot1?.get("chatroomIndex") as! Int
                }
                strongSelf.creatMessageDocument(chatroom2, friendUid, myUid, "friend", count, mymessage) { () in
                    chatroom2.setData(["lastMessage": mymessage, "sender": "friend", "time": Date()], merge: true) { err in
                        chatroom2.setData(["messageCount":count+1], merge: true)
                    }
                    strongSelf.db.collection("users").document(friendUid).getDocument() { (snapshot, error) in
                        var index = snapshot?.get("indexCount") as! Int
                        if index1 != index {
                            index = index + 1
                            chatroom2.setData(["chatroomIndex" : index], merge: true)
                            strongSelf.db.collection("users").document(friendUid).setData(["indexCount" : index], merge: true)
                        }
                    }
                }
             }
        }
        completion(nil)
    }
   
    
    func initiateChatroom(_ myUid : String, _ friendUid : String, _ chatroom : DocumentReference, completion : @escaping (_ chatroom : DocumentReference)->()){
        db.collection("users").document(friendUid).getDocument() { (snapshot, error) in
            let firstName = snapshot?.get("firstName")
            let lastName = snapshot?.get("lastName")
            chatroom.setData(["messageCount": 0, "myUid":myUid, "friendUid":friendUid, "firstName": firstName ?? "firstName", "lastName": lastName ?? "lastName"], merge: true) { err in
                chatroom.collection("messages").document(myUid+friendUid+"!0").setData(["sender":"initialiser", "message":"initialiser"], merge: true) { err in
                    completion(chatroom)
                }
            }
        }
    }
    
    @IBAction func sendMessageTapped(_ sender: Any) {
        if selectedUid != "" {
            getUser(selectedUid: selectedUid) { [weak self] user in
                guard let strongSelf = self else {
                    return
                }
                
                let currentConversations = strongSelf.conversations
                
                if let targetConversation = currentConversations.first(where: {$0.otherUserUid == user.uid
                }) {
                    let vc = ChatViewController(with: targetConversation.otherUserUid, id: targetConversation.id)
                    vc.isNewConversation = false
                    vc.title = targetConversation.name
                    let navigationController = UINavigationController(rootViewController: vc)
                    navigationController.modalPresentationStyle = .fullScreen
                    strongSelf.present(navigationController, animated: true)
                } else {
                    strongSelf.createNewConversation(result: user)
                }
            }
        }
    }
    
    func getUser(selectedUid: String, completion: @escaping(SearchUser) -> Void) {
        let user = SearchUser()
        user.uid = selectedUid
        Firestore.firestore().collection("users").document(selectedUid).getDocument { (snapshot, error) in
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                user.username = dictionary["username"] as? String
                user.firstName = dictionary["firstName"] as? String
                user.lastName = dictionary["lastName"] as? String
                user.profileUrl = dictionary["profileImageUrl"] as? String
            }
            completion(user)
        }
    }
    
    private func createNewConversation(result: SearchUser) {
        let name = result.getName()
        let uid = result.getUid()
        
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
    
    //fetches and returns all conversations for the user with passed in uid
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
    
    func getUserName() {
        db.collection("users").document(userId).getDocument() { [weak self] (snapshot, error) in
            guard let strongSelf = self else {
                return
            }
            strongSelf.selfUsername = snapshot?.get("firstName") as! String
        }
    }
}

extension UIImageView {
    func load(url: URL) {
        DispatchQueue.global().async { [weak self] in
            if let data = try? Data(contentsOf: url) {
                if let image = UIImage(data: data) {
                    DispatchQueue.main.async {
                        self?.image = image
                    }
                }
            }
        }
    }
}

extension UIView {
    func makeCorner(withRadius radius: CGFloat) {
        layer.cornerRadius = radius
        layer.masksToBounds = true
        layer.isOpaque = false
    }
}
 
