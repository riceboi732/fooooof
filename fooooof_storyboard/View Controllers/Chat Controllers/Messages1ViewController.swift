import UIKit
import FirebaseAuth
import FirebaseFirestore
import JGProgressHUD
//import MessageKit
//import AudioToolbox

struct Conversation {
    let id: String
    let name: String
    let otherUserUid: String
    let latestMessage: LatestMessage
}

struct LatestMessage {
    let date: String
    let text: String
    let isRead: String
}

// Controller that shows list of conversations
class Messages1ViewController: UIViewController {
    private let db = Firestore.firestore()
    @IBOutlet var myTable: UITableView!
    @IBOutlet weak var composeButton: UIButton!
    
    private let spinner = JGProgressHUD(style: .dark )
    
    private var conversations = [Conversation]()
    
    private let noConversationsLabel: UILabel = {
        let label = UILabel()
        label.text = "No Conversations!"
        label.textAlignment = .center
        label.textColor = .gray
        label.font = .systemFont(ofSize: 21, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    @IBAction func returnToHome(segue: UIStoryboardSegue){
        //        if listener != nil {
        //            listener?.remove()
        //        }
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    @IBOutlet weak var mapButton: UIButton!
    @IBOutlet weak var messagesViewButton: UIButton!
    @IBOutlet weak var personalProfileButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        checkNameDefaults()
        myTable.layoutMargins = UIEdgeInsets.zero
        myTable.separatorInset = UIEdgeInsets.zero
        view.backgroundColor = UIColor.white
        view.addSubview(noConversationsLabel)
        myTable.isHidden = false
        myTable.register(ChatroomTableViewCell.nib(), forCellReuseIdentifier: "ChatroomTableViewCell")
        myTable.delegate = self
        myTable.dataSource = self
        mapButton.setTitle("", for: .normal)
        messagesViewButton.setTitle("", for: .normal)
        personalProfileButton.setTitle("", for: .normal)
        composeButton.setTitle("", for: .normal)
        startListeningForConversations()
    }
    
    private func checkNameDefaults() {
        if UserDefaults.standard.object(forKey: "firstname") == nil {
            let userUid = Auth.auth().currentUser!.uid
            Firestore.firestore().collection("users").document(userUid).getDocument { (snapshot, error) in
                if let dictionary = snapshot?.data() as? [String: AnyObject]{
                    UserDefaults.standard.set(dictionary["firstName"] as! String, forKey:"firstname")
                    UserDefaults.standard.set(dictionary["lastName"] as! String, forKey:"lastname")
                }
            }
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
                    self?.myTable.isHidden = true
                    self?.noConversationsLabel.isHidden = false
                    return
                }
                self?.noConversationsLabel.isHidden = true
                self?.myTable.isHidden = false
                self?.conversations = conversations
                DispatchQueue.main.async {
                    self?.myTable.reloadData()
                }
            case .failure(let error):
                self?.myTable.isHidden = true
                self?.noConversationsLabel.isHidden = false
                print("failed to get convos: \(error)")
            }
        })
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
    
    @IBAction func composeButtonTapped(_ sender: Any) {
        let vc = storyboard?.instantiateViewController(withIdentifier: "NewConversationViewController") as! NewConversationViewController
        vc.completion = { [weak self] result in
            guard let strongSelf = self else {
                return
            }
            
            let currentConversations = strongSelf.conversations
            
            if let targetConversation = currentConversations.first(where: {$0.otherUserUid == result.uid
            }) {
                let vc = ChatViewController(with: targetConversation.otherUserUid, id: targetConversation.id)
                vc.isNewConversation = false
                vc.title = targetConversation.name
                let navigationController = UINavigationController(rootViewController: vc)
                navigationController.modalPresentationStyle = .fullScreen
                strongSelf.present(navigationController, animated: true)
            } else {
                strongSelf.createNewConversation(result: result)
            }
        }
        present(vc, animated: true)
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
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        noConversationsLabel.frame = CGRect(x: 10, y: (view.bounds.height-100)/2, width: view.bounds.width-20, height: 100)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    //
    @IBAction func personalProfileButtonPressed(_ sender: Any){
        let controller = storyboard?.instantiateViewController(identifier: "personalProfileViewController") as! PersonalProfileViewController
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
}

extension Messages1ViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return conversations.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let model = conversations[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "ChatroomTableViewCell", for: indexPath) as! ChatroomTableViewCell
        cell.layoutMargins = UIEdgeInsets.zero
        //        cell.friendName?.text = "Hello World"
        cell.configure(with: model)
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let model = conversations[indexPath.row]
        openConversation(model)
    }
    
    func openConversation(_ model: Conversation) {
        let vc = ChatViewController(with: model.otherUserUid, id: model.id)
        vc.title = model.name
        let navigationController = UINavigationController(rootViewController: vc)
        navigationController.modalPresentationStyle = .fullScreen
        present(navigationController, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle:  UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            //begin delete
            let conversationId = conversations[indexPath.row].id
            tableView.beginUpdates()
            conversations.remove(at: indexPath.row)
            tableView.deleteRows(at: [indexPath], with: .left )
            tableView.endUpdates()
            deleteConversation(conversationId: conversationId, completion: { success in
                if !success {
                    // add model and row back and show error alert
                }
            })
        }
    }
    
    private func deleteConversation(conversationId: String, completion: @escaping (Bool) -> Void) {
        guard let uid = UserDefaults.standard.value(forKey: "selfUid") as? String else  {
            return
        }
        
        // Get all conversations for current user
        // delete conversation in collection with target id
        // reset those conversations for the user in database
        db.collection("users").document(uid).collection("conversations").whereField("id", isEqualTo: conversationId).getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                querySnapshot!.documents[0].reference.delete() { err in
                    if let err = err {
                        completion(false)
                        print("Error removing conversation: \(err)")
                        return
                    } else {
                        print("Conversation successfully removed!")
                        completion(true)
                        return
                    }
                }
            }
        }
    }
}

