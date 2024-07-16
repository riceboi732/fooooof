//import UIKit
//import MessageKit
//import InputBarAccessoryView
//import FirebaseFirestore
//import AudioToolbox
//
////get rid of initialisers     have a look at chatroom initialiser and message initialiser
//
//
//class Chat1ViewController: MessagesViewController, MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate, InputBarAccessoryViewDelegate {
//
//    var currentUser = Sender(senderId: "self", displayName: "")
//    var otherUser = Sender(senderId: "other", displayName: "")
//    var messages = [(MessageType,Int)]()
//    var messageId = 0
//    var timeInterval = -40000
//    var userName = ""
//    var friendName = ""
//    var userId = ""
//    var friendId = ""
//    var listener : ListenerRegistration? = nil
//    var listener1 : ListenerRegistration? = nil
//    var firstTime = true
//    var buzzIndicator = 1
//    var myImageUrl: URL?
//    var friendImageUrl: URL?
//
//    private let db = Firestore.firestore()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        messagesCollectionView.messagesDataSource = self
//        messagesCollectionView.messagesLayoutDelegate = self
//        messagesCollectionView.messagesDisplayDelegate = self
//        messageInputBar.delegate = self
//        currentUser.displayName = userName
//        otherUser.displayName = friendName
//        creatChatRoom(myUid: userId, friendUid: friendId)
//        snapShotListenerForBuzz()
//    }
//
//
//    func currentSender() -> SenderType {
//        return currentUser
//    }
//
//    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
//        return messages[indexPath.section].0
//    }
//
//    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
//        return messages.count
//    }
//
//    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        guard let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as? MessageContentCell else {
//                    fatalError("Unsupported cell")
//                }
//        let tap1 = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped1))
//        let tap2 = UITapGestureRecognizer(target: self, action: #selector(self.doubleTapped2))
//        tap1.numberOfTapsRequired = 2
//        tap2.numberOfTapsRequired = 2
//        cell.isUserInteractionEnabled = true
//        cell.avatarView.isUserInteractionEnabled = true
//        if messages[indexPath.section].0.sender.senderId == self.currentUser.senderId {
//            cell.avatarView.addGestureRecognizer(tap1)
//        } else {
//            cell.avatarView.addGestureRecognizer(tap2)
//        }
//        return cell
//    }
//
//    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView){
//        if message.sender.senderId == "self" {
////            avatarView.load(url: self.myImageUrl!)
//            avatarView.sd_setImage(with: self.myImageUrl)
//        }
//        if message.sender.senderId == "other" {
////            avatarView.load(url: self.friendImageUrl!)
//            avatarView.sd_setImage(with: self.friendImageUrl)
//        }
//    }
//
//    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String){
//        guard !text.replacingOccurrences(of: "", with: "").isEmpty else {
//            return
//        }
//        inputBar.inputTextView.text = ""
//        updateChat(myUid: userId, friendUid: friendId, mymessage: text) { error in
//        }
//    }
//
//    @objc func doubleTapped1(sender: UITapGestureRecognizer) {
//        shake(sender.view!) { () in
//            DispatchQueue.main.asyncAfter(deadline: .now()+0.16) {
//                self.updateChat(myUid: self.userId, friendUid: self.friendId, mymessage: "\(self.userName) tickled \(self.userName)") { error in
//                    let friendProfile = self.db.collection("users").document(self.friendId)
//                    friendProfile.getDocument() {(snapshot, error) in
//                        if snapshot?.get("buzz") != nil{
//                            if snapshot?.get("buzz") as! Int == 1{
//                                friendProfile.setData(["buzz" : 0], merge: true)
//                            } else {
//                                friendProfile.setData(["buzz" : 1], merge: true)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    @objc func doubleTapped2(sender: UITapGestureRecognizer) {
//        shake(sender.view!) { () in
//            DispatchQueue.main.asyncAfter(deadline: .now()+0.1) {
//                self.updateChat(myUid: self.userId, friendUid: self.friendId, mymessage: "\(self.userName) tickled \(self.friendName)") { error in
//                    let friendProfile = self.db.collection("users").document(self.friendId)
//                    friendProfile.getDocument() {(snapshot, error) in
//                        if snapshot?.get("buzz") != nil{
//                            if snapshot?.get("buzz") as! Int == 1{
//                                friendProfile.setData(["buzz" : 0], merge: true)
//                            } else {
//                                friendProfile.setData(["buzz" : 1], merge: true)
//                            }
//                        }
//                    }
//                }
//            }
//        }
//    }
//
//    func shake(_ viewToShake: UIView, completion : ()->()) {
//        let animation = CABasicAnimation(keyPath: "position")
//        animation.duration = 0.05
//        animation.repeatCount = 3
//        animation.autoreverses = true
//        animation.fromValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x - 3, y: viewToShake.center.y))
//        animation.toValue = NSValue(cgPoint: CGPoint(x: viewToShake.center.x + 3, y: viewToShake.center.y))
//        viewToShake.layer.add(animation, forKey: "position")
//        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//        completion()
//    }
//
//
//    func updateChat(myUid: String, friendUid: String, mymessage: String, completion: @escaping (_ error: Error?) -> Void)->Void{
//        let chatroom = db.collection("users").document(myUid).collection("chats").document(friendUid)
//        chatroom.getDocument{(snapshot,error) in
//            if let error = error{
//                print("\(error)")
//                completion(error)
//            } else {
//                var count1 = 0
//                if snapshot?.get("messageCount") != nil {
//                    count1 = snapshot?.get("messageCount") as! Int
//                }
//                self.creatMessageDocument(chatroom, myUid, friendUid, "me", count1, mymessage) { () in
//                    chatroom.getDocument() { (snapshot, error) in
//                        self.db.collection("users").document(myUid).getDocument() { (snapshot1, error) in
//                            var index = snapshot1?.get("indexCount") as! Int
//                            if snapshot?.get("chatroomIndex") == nil {
//                                chatroom.setData(["chatroomIndex" : index + 1], merge: true) { err in
//                                    chatroom.setData(["lastMessage": mymessage, "sender": "me", "time": Date()], merge: true) { err in
//                                        chatroom.setData(["messageCount":count1+1], merge: true)
//                                    }
//                                }
//                                self.db.collection("users").document(myUid).setData(["indexCount" : index + 1], merge: true)
//                                self.db.collection("users").document(myUid).getDocument() {(snapshot, error) in
//                                    let chatRoomCount = snapshot1?.get("chatRoomCount") as! Int + 1
//                                    self.db.collection("users").document(myUid).setData(["chatRoomCount" : chatRoomCount], merge: true)
//                                }
//                            } else if snapshot?.get("chatroomIndex") as! Int != index {
//                                index = index + 1
//                                chatroom.setData(["chatroomIndex" : index], merge: true) { err in
//                                    chatroom.setData(["lastMessage": mymessage, "sender": "me", "time": Date()], merge: true) { err in
//                                        chatroom.setData(["messageCount":count1+1], merge: true)
//                                    }
//                                }
//                                self.db.collection("users").document(myUid).setData(["indexCount" : index], merge: true)
//                            } else {
//                                chatroom.setData(["lastMessage": mymessage, "sender": "me", "time": Date()], merge: true) { err in
//                                    chatroom.setData(["messageCount":count1+1], merge: true)
//                                }
//                            }
//                        }
//                    }
//                }
//            }
//        }
//        // delete the initialiser part
//        let chatroom2 = db.collection("users").document(friendUid).collection("chats").document(myUid)
//        chatroom2.getDocument{(snapshot1,error) in
//            if let error = error{
//                print("\(error)")
//                completion(error)
//            } else {
//                var index1 = 0
//                var count = 0
//                if snapshot1!.get("messageCount") == nil {
//                    chatroom2.setData(["chatroomIndex" : 0], merge: true)
//                    self.initiateChatroom(friendUid, myUid, chatroom2) { (chatroom2) in
//                    }
//                    let chatPage = self.db.collection("users").document(friendUid)
//                    chatPage.getDocument(){ (snapshot, error) in
//                        if error != nil {
//                            print("Error")
//                        } else {
//                            var count = snapshot?.get("chatRoomCount") as! Int
//                            count = count + 1
//                            self.db.collection("users").document(friendUid).setData(["chatRoomCount" : count],merge: true)
//                        }
//                    }
//                } else {
//                    count = snapshot1!.get("messageCount") as! Int
//                    index1 = snapshot1?.get("chatroomIndex") as! Int
//                }
//                self.creatMessageDocument(chatroom2, friendUid, myUid, "friend", count, mymessage) { () in
//                    chatroom2.setData(["lastMessage": mymessage, "sender": "friend", "time": Date()], merge: true) { err in
//                        chatroom2.setData(["messageCount":count+1], merge: true)
//                    }
//                    self.db.collection("users").document(friendUid).getDocument() { (snapshot, error) in
//                        var index = snapshot?.get("indexCount") as! Int
//                        if index1 != index {
//                            index = index + 1
//                            chatroom2.setData(["chatroomIndex" : index], merge: true)
//                            self.db.collection("users").document(friendUid).setData(["indexCount" : index], merge: true)
//                        } else {
//                            self.db.collection("users").document(friendUid).collection("indicator").document("mostRecent").getDocument() { (snapshot, error) in
//                                if snapshot?.data()?["indicator"] == nil {
//                                    self.db.collection("users").document(friendUid).collection("indicator").document("mostRecent").setData(["indicator" : 1], merge: true)
//                                } else {
//                                    self.db.collection("users").document(friendUid).collection("indicator").document("mostRecent").setData(["indicator" : snapshot?.data()?["indicator"] as! Int + 1], merge: true)
//                                }
//                            }
//                        }
//                    }
//                }
//             }
//        }
//        completion(nil)
//    }
//
//    func creatMessageDocument(_ chatroom2 : DocumentReference,_ myUid: String, _ friendUid : String, _ sender : String, _ count : Int, _ mymessage : String, completion : @escaping ()->()){
//        chatroom2.collection("messages").document(myUid+friendUid+"!"+String(count+1)).setData(["sender":sender, "message":mymessage, "index":count+1],merge: true) { err in
//            completion()
//        }
//    }
//
//    //how to capture messesage when there is no document yet. where to put snapshotlistener?
//    func creatChatRoom(myUid: String, friendUid: String){
//        let chatRoom = db.collection("users").document(myUid).collection("chats").document(friendUid)
//        chatRoom.getDocument(){ (snapshot, error) in
//            if error != nil {
//                print("Error")
//            } else if snapshot!.get("messageCount") == nil {
//                self.initiateChatroom(myUid, friendUid, chatRoom) { (chatRoom) in
//                    self.listener = chatRoom.addSnapshotListener { snapshot, error in
//                        switch (snapshot, error) {
//                                case (.none, .none):
//                                    print("no data")
//                                case (.none, .some(let error)):
//                                    print("some error \(error.localizedDescription)")
//                                case (.some(_), _):
//                                            var count = 0
//                                            chatRoom.getDocument{(snapshot,error) in
//                                                count = snapshot?.get("messageCount") as! Int
//                                                chatRoom.collection("messages").document(myUid+friendUid+"!"+String(count)).getDocument{(snapshot,error) in
//                                                    if (snapshot?.get("index") == nil || snapshot?.get("message") == nil || snapshot?.get("sender") == nil) {
//                                                        return
//                                                    } else {
//                                                        let sender = snapshot?.get("sender") as! String
//                                                        var sender1 : Sender
//                                                        if sender == "friend"{
//                                                            sender1 = self.otherUser
//                                                        } else {
//                                                            sender1 = self.currentUser
//                                                        }
//                                                        let count1 = self.messages.count
//                                                        if self.messages.count == 0 {
//                                                            self.messages.append((Message(sender: sender1, messageId: String(Int(self.messageId)+1), sentDate: Date().addingTimeInterval(TimeInterval(self.timeInterval + 1000)), kind: .text(snapshot?.get("message") as! String)), snapshot?.get("index") as! Int))
//                                                            self.messageId += 1
//                                                            self.messagesCollectionView.reloadData()
//                                                            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
//                                                        } else if self.messages[count1 - 1].1 != snapshot?.get("index") as! Int {
//                                                            self.messages.append((Message(sender: sender1, messageId: String(Int(self.messageId)+1), sentDate: Date().addingTimeInterval(TimeInterval(self.timeInterval + 1000)), kind: .text(snapshot?.get("message") as! String)), snapshot?.get("index") as! Int))
//                                                            self.messageId += 1
//                                                            self.messagesCollectionView.reloadData()
//                                                            self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
//                                                        }
//                                                    }
//
//                                                }
//                                            }
//                        }
//                    }
//                }
//             } else {
//                chatRoom.collection("messages").getDocuments() {(snapshots, error) in
//                    if let error = error {
//                        print("Error getting documents: \(error)")
//                    } else {
//                        for document in snapshots!.documents {
//                            if document.documentID != myUid+friendUid+"!0" {
//                                let message = document.data()["message"] as! String
//                                let sender = document.data()["sender"] as! String
//                                var sender1 : Sender
//                                if sender == "friend"{ //need to change later
//                                    sender1 = self.otherUser
//                                } else {
//                                    sender1 = self.currentUser
//                                }
//                                self.messages.append((Message(sender: sender1, messageId: String(Int(self.messageId)+1), sentDate: Date().addingTimeInterval(TimeInterval(self.timeInterval + 1000)), kind: .text(message)), document.data()["index"] as! Int))
//                                self.messageId += 1
//                            }
//                        }
//                        self.messages = self.messages.sorted(by: {$0.1 < $1.1})
//                        self.messageId -= 1
//                        self.messagesCollectionView.reloadData()
//                        self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
//                    }
//
//                }
//                 self.listener = chatRoom.addSnapshotListener { snapshot, error in
//                     switch (snapshot, error) {
//                             case (.none, .none):
//                                 print("no data")
//                             case (.none, .some(let error)):
//                                 print("some error \(error.localizedDescription)")
//                             case (.some(_), _):
//                                         var count = 0
//                                         chatRoom.getDocument{(snapshot,error) in
//                                             count = snapshot?.get("messageCount") as! Int
//                                             chatRoom.collection("messages").document(myUid+friendUid+"!"+String(count)).getDocument{(snapshot,error) in
//                                                 if (snapshot?.get("index") == nil || snapshot?.get("message") == nil || snapshot?.get("sender") == nil) {
//                                                     return
//                                                 } else {
//                                                     let sender = snapshot?.get("sender") as! String
//                                                     var sender1 : Sender
//                                                     if sender == "friend"{
//                                                         sender1 = self.otherUser
//                                                     } else {
//                                                         sender1 = self.currentUser
//                                                     }
//                                                     let count1 = self.messages.count
//                                                     if self.messages.count == 0 {
//                                                         self.messages.append((Message(sender: sender1, messageId: String(Int(self.messageId)+1), sentDate: Date().addingTimeInterval(TimeInterval(self.timeInterval + 1000)), kind: .text(snapshot?.get("message") as! String)), snapshot?.get("index") as! Int))
//                                                         self.messageId += 1
//                                                         self.messagesCollectionView.reloadData()
//                                                         self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
//                                                     } else if self.messages[count1 - 1].1 != snapshot?.get("index") as! Int {
//                                                         self.messages.append((Message(sender: sender1, messageId: String(Int(self.messageId)+1), sentDate: Date().addingTimeInterval(TimeInterval(self.timeInterval + 1000)), kind: .text(snapshot?.get("message") as! String)), snapshot?.get("index") as! Int))
//                                                         self.messageId += 1
//                                                         self.messagesCollectionView.reloadData()
//                                                         self.messagesCollectionView.scrollToLastItem(at: .bottom, animated: true)
//                                                     }
//                                                 }
//                                             }
//                                         }
//                     }
//                 }
//              }
//            }
//    }
//
//    func initiateChatroom(_ myUid : String, _ friendUid : String, _ chatroom : DocumentReference, completion : @escaping (_ chatroom : DocumentReference)->()){
//        self.db.collection("users").document(friendUid).getDocument() { (snapshot, error) in
//            let firstName = snapshot?.get("firstName")
//            let lastName = snapshot?.get("lastName")
//            chatroom.setData(["messageCount": 0, "myUid":myUid, "friendUid":friendUid, "firstName": firstName, "lastName": lastName], merge: true) { err in
//                chatroom.collection("messages").document(myUid+friendUid+"!0").setData(["sender":"initialiser", "message":"initialiser"], merge: true) { err in
//
//                    completion(chatroom)
//                }
//            }
//        }
//    }
//
//    func snapShotListenerForBuzz() {
//        self.listener1 = self.db.collection("users").document(userId).addSnapshotListener { snapshot, error in
//            switch (snapshot, error) {
//                    case (.none, .none):
//                        print("no data")
//                    case (.none, .some(let error)):
//                        print("some error \(error.localizedDescription)")
//                    case (.some(_), _):
//                        if self.firstTime == true {
//                            self.buzzIndicator = 1
//                            self.db.collection("users").document(self.userId).setData(["buzz" : 1], merge: true)
//                            self.firstTime = false
//                        } else {
//                            if snapshot?.get("buzz") as! Int != self.buzzIndicator {
//                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
//                                self.buzzIndicator = snapshot?.get("buzz") as! Int
//                                var i = self.messages.count - 1
//                                while i >= 0 {
//                                    if self.messages[i].0.sender.senderId == "other" {
//                                        guard let cell = self.messagesCollectionView.cellForItem(at: IndexPath(row: 0, section: i)) as? MessageContentCell else {
//                                                    fatalError("Unsupported cell")
//                                                }
//                                        self.shake(cell.avatarView) { () in
//                                        }
//                                        i = -1
//                                    } else {
//                                        i = i - 1
//                                    }
//                                }
//                            }
//                        }
//            }
//        }
//    }
//
//    func onAppIndication(_ userId: String) {
//        self.db.collection("users").document(userId).setData(["onApp":1],merge: true)
//    }
//
//    func offAppIndication(_ userId: String) {
//        self.db.collection("users").document(userId).setData(["onApp":0],merge: true)
//    }
//
//
//    override func viewDidDisappear(_ animated: Bool) {
//        if listener != nil {
//            listener?.remove()
//        }
//        if listener1 != nil {
//            listener1?.remove()
//        }
//        let chatroom = db.collection("users").document(userId).collection("chats").document(friendId)
//        chatroom.getDocument() { (snapshot, error) in
//            if snapshot?.get("chatroomIndex") == nil {
//                chatroom.collection("messages").document(self.userId+self.friendId+"!0").delete()
//                chatroom.delete()
//            }
//        }
//    }
//
//}
