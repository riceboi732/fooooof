import UIKit
import MessageKit
import InputBarAccessoryView
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation
//import AudioToolbox



struct Message: MessageType {
    public var sender: SenderType
    public var messageId: String
    public var sentDate: Date
    public var kind: MessageKind
}

extension MessageKind {
    var messageKindString: String {
        switch self {
        case .text(_):
            return "text"
        case .attributedText(_):
            return "attributed_text"
        case .photo(_):
            return "photo"
        case .video(_):
            return "video"
        case .location(_):
            return "location"
        case .emoji(_):
            return "emoji"
        case .audio(_):
            return "audio"
        case .contact(_):
            return "contact"
        case .linkPreview(_):
            return "link_preview"
        case .custom(_):
            return "custom"
        }
    }
}

struct Sender: SenderType {
    public var photoURL: String
    public var senderId: String
    public var displayName: String
}

struct Media: MediaItem {
    var url: URL?
    var image: UIImage?
    var placeholderImage: UIImage
    var size: CGSize
}

struct Location: LocationItem {
    var location: CLLocation
    var size: CGSize
}

class ChatViewController: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        // necessary to avoid daylight saving (and other time shift) problems
        formatter.timeZone = TimeZone(secondsFromGMT: TimeZone.current.secondsFromGMT())
        // necessary to avoid problems with 12h vs 24h time formatting
        formatter.locale = Locale(identifier: "en_US_POSIX")
        return formatter
    }()
    
    public let otherUid: String
    private var conversationId: String?
    public var isNewConversation = false
    private let db = Firestore.firestore()
    private var messages = [Message]()
    public typealias UploadPictureCompletion = (Result<String, Error>) -> Void
    
    private var selfSender: Sender? {
        guard let selfUid = UserDefaults.standard.value(forKey: "selfUid") else {
            return nil
        }
        
        return Sender(photoURL: "",
                      senderId: selfUid as! String,
                      displayName: "Me")
    }
    
    init(with uid: String, id: String?) {
        self.conversationId = id
        self.otherUid = uid
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.setupTopBar()
        self.setupInputButton()
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
    }
    
    private func setupTopBar() {
        let button: UIButton = UIButton()
        button.setImage(UIImage(systemName: "chevron.left"), for: .normal)
        button.tintColor = UIColor(named: "fooooofRed")
        button.frame = CGRectMake(0, 0, 40, 40)
        button.addTarget(self, action: #selector(buttonAction), for: .touchUpInside)
        let leftBarButtonItem:UIBarButtonItem = UIBarButtonItem()
        leftBarButtonItem.customView = button
        
        let negativeSpacer:UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.fixedSpace, target: nil, action: nil)
        negativeSpacer.width = -20; // set the value you need
        self.navigationItem.leftBarButtonItems  = [negativeSpacer,leftBarButtonItem]
        view.backgroundColor = .white
    }
    
    private func setupInputButton() {
        let button = InputBarButtonItem()
        
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "plus"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = UIColor(named: "fooooofRed")
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.inputTextView.textContainerInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        messageInputBar.inputTextView.placeholderLabelInsets = UIEdgeInsets(top: 8, left: 20, bottom: 8, right: 20)
        messageInputBar.sendButton.setTitleColor(UIColor(named: "fooooofRed"), for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor(named: "fooooofRed"),
            for: .highlighted)
        if #available(iOS 13, *) {
            messageInputBar.inputTextView.layer.borderColor = UIColor.systemGray5.cgColor
        } else {
            messageInputBar.inputTextView.layer.borderColor = UIColor.lightGray.cgColor
        }
        //
        //adding border to chatbox
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 20.0
        messageInputBar.inputTextView.layer.masksToBounds = true
        //
        messageInputBar.inputTextView.scrollIndicatorInsets = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
        
        messageInputBar.shouldAnimateTextDidChangeLayout = true
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media", message: "What would you like to attach?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo", style: .default, handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video", style: .default, handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio", style: .default, handler: { _ in
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Location", style: .default, handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentLocationPicker() {
        let vc = LocationPickerViewController(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoordinates in
            
            guard let strongSelf = self else {
                return
            }
            
            guard let messageId = strongSelf.createMessageId(),
                  let conversationId = strongSelf.conversationId,
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let longitude: Double = selectedCoordinates.longitude
            let latitude: Double = selectedCoordinates.latitude
            
            print("long=\(longitude) | lat=\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude, longitude: longitude), size: .zero)
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            
            self?.sendMessage(to: conversationId, otherUserUid: strongSelf.otherUid, name: name, newMessage: message, completion: { success in
                if success {
                    print("sent location message")
                } else {
                    print("failed to send location message")
                }
            })
        }
        navigationController?.pushViewController(vc, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo", message: "Where would you like to attach a photo from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video", message: "Where would you like to attach a video from?", preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library", style: .default, handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        getAllMessagesForConversation(with: id, completion: { [weak self] result in
            switch result {
            case .success(let messages):
                guard !messages.isEmpty else {
                    return
                }
                self?.messages = messages
                
                DispatchQueue.main.async {
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem()
                    }
                }
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        messageInputBar.inputTextView.becomeFirstResponder()
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    @objc func buttonAction(sender: UIButton!){
        self.navigationController?.popViewController(animated: false)
        self.dismiss(animated: true, completion: nil)
    }
}

extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        guard let messageId = createMessageId(),
              let conversationId = conversationId,
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        if let image = info[.editedImage] as? UIImage, let imageData = image.pngData() {
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
            
            //Upload image
            uploadMessagePhoto(with: imageData, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //Ready to send message
                    print("Uploaded Message Photo: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .photo(media))
                    
                    self?.sendMessage(to: conversationId, otherUserUid: strongSelf.otherUid, name: name, newMessage: message, completion: { success in
                        
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                        
                    })
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        } else if let videoUrl = info[.mediaURL] as? URL{
            let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
            
            //Upload Video
            uploadMessageVideo(with: videoUrl, fileName: fileName, completion: { [weak self] result in
                guard let strongSelf = self else {
                    return
                }
                switch result {
                case .success(let urlString):
                    //Ready to send message
                    print("Uploaded Message Video: \(urlString)")
                    
                    guard let url = URL(string: urlString),
                          let placeholder = UIImage(systemName: "plus") else {
                        return
                    }
                    
                    let media = Media(url: url,
                                      image: nil,
                                      placeholderImage: placeholder,
                                      size: .zero)
                    
                    let message = Message(sender: selfSender,
                                          messageId: messageId,
                                          sentDate: Date(),
                                          kind: .video(media))
                    
                    self?.sendMessage(to: conversationId, otherUserUid: strongSelf.otherUid, name: name, newMessage: message, completion: { success in
                        
                        if success {
                            print("sent photo message")
                        } else {
                            print("failed to send photo message")
                        }
                        
                    })
                    
                case .failure(let error):
                    print("message photo upload error: \(error)")
                }
            })
        }
        
        //Send message
        
    }
    
    //upload image that will be sent in a conversation message
    public func uploadMessagePhoto(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        let storage = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
        storage.child("message_images/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
            guard error == nil else {
                //failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageError.unknown))
                return
            }
            
            storage.child("message_images/\(fileName)").downloadURL(completion: { url, error in
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
    
    //upload video that will be sent in a conversation message
    public func uploadMessageVideo(with fileUrl: URL, fileName: String, completion: @escaping UploadPictureCompletion) {
        let storage = Storage.storage().reference(forURL: "gs://fooooof-testflight.appspot.com")
        do {
            let data = try Data(contentsOf: fileUrl)
            storage.child("message_videos/\(fileName)").putData(data, metadata: nil, completion: { metadata, error in
                guard error == nil else {
                    //failed
                    print("failed to upload video file to firebase for picture")
                    completion(.failure(StorageError.unknown))
                    return
                }
                
                storage.child("message_videos/\(fileName)").downloadURL(completion: { url, error in
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
        } catch {
            print("-- Error: \(error)")
        }
    }
}

extension ChatViewController: InputBarAccessoryViewDelegate {
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        // Send Message
        if isNewConversation {
            //create convo in database
            print("Creating a new conversation")
            createNewConversation(with: otherUid, name: title ?? "User", firstMessage: message, completion: { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                } else {
                    print("failed to send")
                }
            })
        } else {
            print("calling sendMessage for old conversation")
            guard let conversationId = conversationId, let name = title else {
                return
            }
            //append to existing conversation data
            sendMessage(to: conversationId, otherUserUid: otherUid, name: name, newMessage: message, completion: { success in
                if success {
                    print("message sent")
                } else {
                    print("failed to send")
                }
            })
        }
        inputBar.inputTextView.text = ""
    }
    
    private func createMessageId() -> String? {
        //date, otherUid, senderUid, randomInt
        guard let currentUserUid = UserDefaults.standard.value(forKey: "selfUid") else {
            return nil
        }
        
        let dateString = ChatViewController.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUid)_\(currentUserUid)_\(dateString)"
        
        print("Created message id: \(newIdentifier)")
        
        return newIdentifier
    }
    
    //creates a new conversation with target user email and for first message sent
    func createNewConversation(with otherUserUid: String, name: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        guard let currentUid = UserDefaults.standard.value(forKey: "selfUid") as? String,
              let currentFirstName = UserDefaults.standard.value(forKey: "firstname") as? String,
              let currentLastName = UserDefaults.standard.value(forKey: "lastname") as? String else {
            print("not getting userdefault values")
            return
        }
        let ref = db.collection("users").document(currentUid);
        ref.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                
                let messageDate = firstMessage.sentDate
                let dateString = ChatViewController.dateFormatter.string(from: messageDate)
                
                var message = ""
                
                switch firstMessage.kind {
                case .text(let messageText):
                    message = messageText
                case .attributedText(_):
                    break
                case .photo(_):
                    break
                case .video(_):
                    break
                case .location(_):
                    break
                case .emoji(_):
                    break
                case .audio(_):
                    break
                case .contact(_):
                    break
                case .custom(_):
                    break
                case .linkPreview(_):
                    break
                }
                
                let conversationId = "conversation_\(firstMessage.messageId)"
                
                let newConversationData: [String: Any] = [
                    "id": conversationId,
                    "other_user_uid": otherUserUid,
                    "name": name,
                    "latest_message": [
                        "date": dateString,
                        "message": message,
                        "is_read": "false"
                    ]
                ]
                
                let recipient_newConversationData: [String: Any] = [
                    "id": conversationId,
                    "other_user_uid": currentUid,
                    "name": "\(currentFirstName) \(currentLastName)",
                    "latest_message": [
                        "date": dateString,
                        "message": message,
                        "is_read": "false"
                    ]
                ]
                
                self?.db.collection("blocked").document(otherUserUid).getDocument { (snapshot, error) in
                    if let dictionary = snapshot?.data() as? [String: AnyObject]{
                        let blocked = dictionary[currentUid] as? Bool
                        if blocked == nil {
                            print("This user is not blocked")
                            //ONLY UPDATE IF NOT BLOCKED
                            //Update recipient user conversation entry
                            let recipientConversationRef = strongSelf.db.collection("users").document(otherUserUid).collection("conversations");
                            recipientConversationRef.getDocuments { (snapshot, error) in
                                recipientConversationRef.addDocument(data: recipient_newConversationData)
                            }
                        } else if blocked == true {
                            print("This user is blocked")
                        } else {
                            print("This user was blocked but now isn't blocked")
                            //ONLY UPDATE IF NOT BLOCKED
                            //Update recipient user conversation entry
                            let recipientConversationRef = strongSelf.db.collection("users").document(otherUserUid).collection("conversations");
                            recipientConversationRef.getDocuments { (snapshot, error) in
                                recipientConversationRef.addDocument(data: recipient_newConversationData)
                            }
                        }
                    }
                }
                
                //Update current user conversation entry
                let conversationRef = strongSelf.db.collection("users").document(currentUid).collection("conversations");
                conversationRef.getDocuments { (snapshot, error) in
                    conversationRef.addDocument(data: newConversationData)
                    strongSelf.finishCreatingConversation(name: name,
                                                          conversationID: conversationId,
                                                          firstMessage: firstMessage,
                                                          completion: completion)
                }
            } else {
                completion(false)
                print("user not found")
                return
            }
        }
    }
    
    private func finishCreatingConversation(name: String, conversationID: String, firstMessage: Message, completion: @escaping (Bool) -> Void) {
        
        let messageDate = firstMessage.sentDate
        let dateString = ChatViewController.dateFormatter.string(from: messageDate)
        var message = ""
        
        switch firstMessage.kind {
        case .text(let messageText):
            message = messageText
        case .attributedText(_):
            break
        case .photo(_):
            break
        case .video(_):
            break
        case .location(_):
            break
        case .emoji(_):
            break
        case .audio(_):
            break
        case .contact(_):
            break
        case .custom(_):
            break
        case .linkPreview(_):
            break
        }
        
        guard let currentUserUid = UserDefaults.standard.value(forKey: "selfUid") as? String else {
            completion(false)
            return
        }
        
        //add "blocked": "true" field to collectionMessage if applicable before adding to conversations collection
        self.db.collection("blocked").document(otherUid).getDocument { [weak self] (snapshot, error) in
            if let dictionary = snapshot?.data() as? [String: AnyObject]{
                let blocked = dictionary[currentUserUid] as? Bool
                if blocked == nil {
                    print("This user is not blocked")
                    let collectionMessage: [String: Any] = [
                        "id": firstMessage.messageId,
                        "type": firstMessage.kind.messageKindString,
                        "content": message,
                        "date": dateString,
                        "sender_uid": currentUserUid,
                        "is_read": "false",
                        "name": name,
                        "timestamp": FieldValue.serverTimestamp(),
                        "blocked": "false"
                    ]
                    let ref = self?.db.collection("conversations").document("\(conversationID)").collection("messages")
                    ref?.addDocument(data: collectionMessage) { err in
                        if err != nil {
                            print("error sending message")
                            completion(false)
                            return
                        } else {
                            completion(true)
                        }
                    }
                } else if blocked == true {
                    print("This user is blocked")
                    var collectionMessage: [String: Any] = [
                        "id": firstMessage.messageId,
                        "type": firstMessage.kind.messageKindString,
                        "content": message,
                        "date": dateString,
                        "sender_uid": currentUserUid,
                        "is_read": "false",
                        "name": name,
                        "timestamp": FieldValue.serverTimestamp(),
                        "blocked": "true"
                    ]
                    let ref = self?.db.collection("conversations").document("\(conversationID)").collection("messages")
                    ref?.addDocument(data: collectionMessage) { err in
                        if err != nil {
                            print("error sending message")
                            completion(false)
                            return
                        } else {
                            completion(true)
                        }
                    }
                } else {
                    print("This user was blocked but now isn't blocked")
                    let collectionMessage: [String: Any] = [
                        "id": firstMessage.messageId,
                        "type": firstMessage.kind.messageKindString,
                        "content": message,
                        "date": dateString,
                        "sender_uid": currentUserUid,
                        "is_read": "false",
                        "name": name,
                        "timestamp": FieldValue.serverTimestamp(),
                        "blocked": "false"
                    ]
                    let ref = self?.db.collection("conversations").document("\(conversationID)").collection("messages")
                    ref?.addDocument(data: collectionMessage) { err in
                        if err != nil {
                            print("error sending message")
                            completion(false)
                            return
                        } else {
                            completion(true)
                        }
                    }
                }
            }
        }
    }
    
    //gets all messages for a given conversation
    func getAllMessagesForConversation(with id: String, completion: @escaping (Result<[Message], Error>) -> Void) {
        db.collection("conversations").document(id).collection("messages").order(by: "timestamp").addSnapshotListener { [weak self] querySnapshot, error in
            guard let strongSelf = self else {
                return
            }
            guard let documents = querySnapshot?.documents else {
                print("Error fetching conversation documents: \(error!)")
                return
            }
            var messages: [Message] = []
            for document in documents {
                let dictionary = document.data()
                guard let name = dictionary["name"] as? String,
                      let isRead = dictionary["is_read"] as? String,
                      let messageId = dictionary["id"] as? String,
                      let content = dictionary["content"] as? String,
                      let senderUid = dictionary["sender_uid"] as? String,
                      let type = dictionary["type"] as? String,
                      let dateString = dictionary["date"] as? String,
                      let date = ChatViewController.dateFormatter.date(from:dateString)
                else {
                    print("Messages info not the right type or missing")
                    return
                }
                let blocked = dictionary["blocked"] as? String ?? ""
                var kind: MessageKind?
                if type == "photo" {
                    //photo
                    guard let imageUrl = URL(string: content),
                          let placeHolder = UIImage(systemName: "plus") else {
                        print("photo url not working")
                        return
                    }
                    let media = Media(url: imageUrl,
                                      image: nil,
                                      placeholderImage: placeHolder,
                                      size: CGSize(width: 300, height: 300))
                    kind = .photo(media)
                } else if type == "video" {
                    //video
                    guard let videoUrl = URL(string: content) else {
                        print("video url not working")
                        return
                    }
                    if let thumbnailImage = strongSelf.getThumbnailImage(forUrl: videoUrl) {
                        let media = Media(url: videoUrl,
                                          image: nil,
                                          placeholderImage: thumbnailImage,
                                          size: CGSize(width: 300, height: 300))
                        kind = .video(media)
                    }
                } else if type == "location" {
                    let locationComponents = content.components(separatedBy: ",")
                    guard let longitude = Double(locationComponents[0]),
                          let latitude = Double(locationComponents[1]) else {
                        return
                    }
                    print("Rendering location; long=\(longitude) | lat=\(latitude)")
                    let location = Location(location: CLLocation(latitude: latitude, longitude: longitude),
                                            size: CGSize(width: 300, height: 300))
                    kind = .location(location)
                } else {
                    kind = .text(content)
                }
                
                guard let finalKind = kind else {
                    return
                }
                
                let sender = Sender(photoURL: "",
                                    senderId: senderUid,
                                    displayName: name)
                
                // append to message only if message is not blocked
                guard let selfUid = UserDefaults.standard.value(forKey: "selfUid") else {
                    return
                }
                // append to messages only if message is not blocked
                if blocked == "false" || blocked == "" {
                    messages.append(Message(sender: sender,
                                            messageId: messageId,
                                            sentDate: date,
                                            kind: finalKind))
                    
                } else if senderUid == selfUid as! String {
                    messages.append(Message(sender: sender,
                                            messageId: messageId,
                                            sentDate: date,
                                            kind: finalKind))
                } else {
                    //don't add this to the list of messages since the recipient has blocked this message after they blocked the sender.
                }
            }
            completion(.success(messages))
        }
    }
    
    func getThumbnailImage(forUrl url: URL) -> UIImage? {
        let asset: AVAsset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(value: 1, timescale: 60), actualTime: nil)
            return UIImage(cgImage: thumbnailImage)
        } catch let error {
            print(error)
        }
        
        return nil
    }
    
    //sends a message with target conversation with message
    func sendMessage(to conversation: String, otherUserUid: String, name: String, newMessage: Message, completion: @escaping (Bool) -> Void) {
        //add new message to messages
        //update sender latest message
        //update recipient latest message
        print("calling function sendMessage 1")
        guard let currentUid = UserDefaults.standard.value(forKey: "selfUid") as? String else {
            completion(false)
            return
        }
        
        let ref = db.collection("conversations").document(conversation).collection("messages")
        ref.getDocuments() { [weak self] querySnapshot, error in
            guard (querySnapshot?.documents) != nil else {
                print("Error fetching conversation documents: \(error!)")
                completion(false)
                return
            }
            
            let messageDate = newMessage.sentDate
            let dateString = ChatViewController.dateFormatter.string(from: messageDate)
            var message = ""
            
            switch newMessage.kind {
            case .text(let messageText):
                message = messageText
            case .attributedText(_):
                break
            case .photo(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .video(let mediaItem):
                if let targetUrlString = mediaItem.url?.absoluteString {
                    message = targetUrlString
                }
                break
            case .location(let locationData):
                let location = locationData.location
                message = "\(location.coordinate.longitude),\(location.coordinate.latitude)"
                break
            case .emoji(_):
                break
            case .audio(_):
                break
            case .contact(_):
                break
            case .custom(_):
                break
            case .linkPreview(_):
                break
            }
            
            guard let currentUserUid = UserDefaults.standard.value(forKey: "selfUid") as? String else {
                completion(false)
                return
            }
            
            // If I am blocked, then my message should not show up on their side
            // Message should not show if block: true and sender_uid != currentUserUid
            
            // Alternatively: only display message in individual chat if “blocked”==“false” or no blocked field
            // or blocked == true AND sender_uid == currentUserUid
            
            // Add in blocked : true if blocked/otherUserUid/currentUserUid == true
            
            print("calling function sendMessage 2")
            //IF CURRENT USER BLOCKED BY RECIPIENT: add newmessageentry with blocked field into conversations database & don't updateLatestMessage for recipient
            self?.db.collection("blocked").document(otherUserUid).getDocument { (snapshot, error) in
                var newMessageEntry: [String: Any] = [
                    "id": newMessage.messageId,
                    "type": newMessage.kind.messageKindString,
                    "content": message,
                    "date": dateString,
                    "sender_uid": currentUserUid,
                    "is_read": "false",
                    "name": name,
                    "timestamp": FieldValue.serverTimestamp(),
                    "blocked": "false"
                ]
                if snapshot?.exists ?? false {
                    // EXIST
                    print("snapshot exists")
                } else {
                    // NOT EXIST
                    print("snapshot doesn't exist")
                    print("This user is not blocked")
                    self?.notBlockedUpdateLatestMessage(newMessage: newMessage, message: message, dateString: dateString, currentUserUid: currentUserUid, name: name, ref: ref, conversation: conversation, currentUid: currentUid, otherUserUid: otherUserUid, blocked: false, newMessageEntry: newMessageEntry) { success in
                        if success {
                            completion(true)
                        } else {
                            completion(false)
                        }
                    }
                }
                
                if let dictionary = snapshot?.data() as? [String: AnyObject]{
                    let blocked = dictionary[currentUserUid] as? Bool
                    if blocked == nil {
                        print("This user is not blocked")
                        self?.notBlockedUpdateLatestMessage(newMessage: newMessage, message: message, dateString: dateString, currentUserUid: currentUserUid, name: name, ref: ref, conversation: conversation, currentUid: currentUid, otherUserUid: otherUserUid, blocked: false, newMessageEntry: newMessageEntry) { success in
                            if success {
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                    } else if blocked == true {
                        print("This user is blocked")
                        newMessageEntry = [
                            "id": newMessage.messageId,
                            "type": newMessage.kind.messageKindString,
                            "content": message,
                            "date": dateString,
                            "sender_uid": currentUserUid,
                            "is_read": "false",
                            "name": name,
                            "timestamp": FieldValue.serverTimestamp(),
                            "blocked": "true"
                        ]
                        
                        self?.notBlockedUpdateLatestMessage(newMessage: newMessage, message: message, dateString: dateString, currentUserUid: currentUserUid, name: name, ref: ref, conversation: conversation, currentUid: currentUid, otherUserUid: otherUserUid, blocked: true, newMessageEntry: newMessageEntry) { success in
                            if success {
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                        
                    } else {
                        print("This user was blocked but now isn't blocked")
                        self?.notBlockedUpdateLatestMessage(newMessage: newMessage, message: message, dateString: dateString, currentUserUid: currentUserUid, name: name, ref: ref, conversation: conversation, currentUid: currentUid, otherUserUid: otherUserUid, blocked: false, newMessageEntry: newMessageEntry) { success in
                            if success {
                                completion(true)
                            } else {
                                completion(false)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func updateLatestMessage(currentUid: String, conversation: String, dateString: String, message: String, otherUserUid: String, name: String, completion: @escaping (Bool) -> Void) {
        db.collection("users").document(currentUid).collection("conversations").whereField("id", isEqualTo: conversation).getDocuments { (result, error) in
            let updatedValue: [String: Any] = [
                "date": dateString,
                "is_read": "false",
                "message": message
            ]
            if error != nil {
                print("Error fetching conversation documents: \(error!)")
                completion(false)
                return
            } else if (result!.documents.count == 0){
                let newConversationData: [String: Any] = [
                    "id": conversation,
                    "other_user_uid": otherUserUid,
                    "name": name,
                    "latest_message": updatedValue
                ]
                
                self.db.collection("users").document(currentUid).collection("conversations").addDocument(data: newConversationData) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Self conversation document added")
                    }
                }
            } else {
                for document in result!.documents {
                    self.db.collection("users").document(currentUid).collection("conversations").document(document.documentID).setData(["latest_message":updatedValue], merge: true)
                }
            }
        }
    }
    
    func notBlockedUpdateLatestMessage(newMessage: Message, message: String, dateString: String, currentUserUid: String, name: String, ref: CollectionReference, conversation: String, currentUid: String, otherUserUid: String, blocked: Bool, newMessageEntry: [String: Any], completion: @escaping (Bool) -> Void) {
        
        ref.addDocument(data: newMessageEntry) { [weak self] error in
            guard error == nil else {
                completion(false)
                return
            }
            
            guard let strongSelf = self else {
                completion(false)
                return
            }
            
            //update latest message for current (sender) user
            
            strongSelf.updateLatestMessage(currentUid: currentUid, conversation: conversation, dateString: dateString, message: message, otherUserUid: otherUserUid, name: name) { success in
                if success {
                    completion(true)
                } else {
                    completion(false)
                }
            }
            
            if blocked != true {
                //update latest message for recipient user
                guard let currentFirstName = UserDefaults.standard.value(forKey: "firstname") as? String,
                      let currentLastName = UserDefaults.standard.value(forKey: "lastname") as? String else{
                    return
                }
                
                let currentName = "\(currentFirstName) \(currentLastName)"
                
                strongSelf.updateLatestMessage(currentUid: otherUserUid, conversation: conversation, dateString: dateString, message: message, otherUserUid: currentUid, name: currentName) { success in
                    if success {
                        completion(true)
                    } else {
                        completion(false)
                    }
                }
            }
            completion(true)
        }
    }
}

extension ChatViewController: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate  {
    func currentSender() -> MessageKit.SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, selfUid should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessageKit.MessagesCollectionView) -> MessageKit.MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
    }
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our message that we've sent
            return UIColor(named: "fooooofRed")!.withAlphaComponent(0.15)
        }
        return UIColor.lightGray.withAlphaComponent(0.15)
    }
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return UIColor.black
    }
    
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            // show our image
            if let currentUserImageURL = senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImageURL, completed: nil)
            } else {
                // fetch url
                findProfileImageUrl(uid: sender.senderId) { [weak self] urlString in
                    guard let strongSelf = self else {
                        return
                    }
                    DispatchQueue.main.async {
                        avatarView.sd_setImage(with: URL(string: urlString))
                        strongSelf.senderPhotoURL = URL(string: urlString)
                    }
                }
            }
        } else {
            // other user image
            if let otherUserImageURL = otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserImageURL, completed: nil)
            } else {
                // fetch url
                findProfileImageUrl(uid: sender.senderId) { [weak self] urlString in
                    guard let strongSelf = self else {
                        return
                    }
                    DispatchQueue.main.async {
                        avatarView.sd_setImage(with: URL(string: urlString))
                        strongSelf.otherUserPhotoURL = URL(string: urlString)
                    }
                }
            }
        }
    }
    
    func findProfileImageUrl(uid: String, completion: @escaping ((String) -> Void)) {
        db.collection("users").document(uid).getDocument() { (snapshot, error) in
            if (snapshot?.get("profileImageUrl") != nil) {
                completion(snapshot?.get("profileImageUrl") as! String)
            }
        }
    }
}

extension ChatViewController: MessageCellDelegate {
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerViewController(coordinates: coordinates)
            
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerViewController(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            vc.player?.play()
            present(vc, animated: true)
        default:
            break
        }
    }
}
