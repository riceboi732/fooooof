import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox

class NewConversationViewController: UIViewController, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, MyTableViewCellDelegate {
    
    public var completion: ((SearchUser) -> (Void))?
    var usersArray = [SearchUser]()
    var filteredUsers = [SearchUser]()
    let db = Firestore.firestore()
    var listener1 : ListenerRegistration? = nil
    var firstTime = true
    var buzzIndicator = 1
    let userId = Auth.auth().currentUser!.uid

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var field: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        tableView.delegate = self
        tableView.register(MyTableViewCell.nib(), forCellReuseIdentifier: MyTableViewCell.identifier)
        tableView.dataSource = self
        field.delegate = self
        getUsers() { [weak self] users in
            guard let strongSelf = self else {
                return
            }
            strongSelf.usersArray = users
            strongSelf.filteredUsers = users
            strongSelf.tableView.reloadData()
        }
        snapShotListenerForBuzz()
    }
    
    func didTapButton(title: String, index: Int) {
        //TODO: add chat function to this button, change title to chat instead of connect in mytableviewcell
        print("add chat function maybe")
    }


    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            if string.isEmpty
            {
                let endIndex = text.count-1
                let start = String.Index(utf16Offset: 0, in: string)
                let end = String.Index(utf16Offset: endIndex, in: string)
                let substring = String(text[start..<end])
                if(endIndex == 0) {
                    filteredUsers = usersArray
                    tableView.reloadData()
                } else {
                    filterText(substring)
                }
            } else {
                filterText(text+string)
            }
        }
        return true
    }

    func filterText(_ query: String) {
        filteredUsers.removeAll()
        for user in usersArray{
            if user.getUsername().lowercased().starts(with: query.lowercased()) {
                filteredUsers.append(user)
            }
        }
        tableView.reloadData()
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !filteredUsers.isEmpty {
            return filteredUsers.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: MyTableViewCell.identifier, for: indexPath) as! MyTableViewCell
        cell.layoutMargins = UIEdgeInsets.zero
        if !filteredUsers.isEmpty {
            cell.friendName?.text = filteredUsers[indexPath.row].getUsername()
            let urlString = filteredUsers[indexPath.row].getProfilePic()
            DispatchQueue.main.async {
                cell.ProfilePic?.sd_setImage(with: URL(string: urlString))
            }
            //TODO: Change this to pending or add friend depending on friend status (write a function for that)
            cell.configure(title: "Connect", index: indexPath.row)
            cell.delegate = self
        } else {
        }
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let targetUserData = filteredUsers[indexPath.row]
        dismiss(animated: true, completion: { [weak self] in self?.completion?(targetUserData)
        })
    }

    func addFriendButtonTapped(friendUID: String) {
            let selfUID = Auth.auth().currentUser!.uid
            let friendUID = friendUID
            if selfUID == friendUID {
                let alert = UIAlertController(title: ":)", message: "You cannot add yourself.\n You're zero degree friend already.", preferredStyle: .alert)
                let okayAction = UIAlertAction(title:"Okay", style: .default) { (action) in
                }
                alert.addAction(okayAction)
                present(alert, animated: true, completion: nil)
            } else {
                addFriendIfNotAlreadyFriends(selfUID: selfUID, friendUID: friendUID)
            }
    }

    func updateSearchResults(for searchController: UISearchController) {
        guard searchController.searchBar.text != nil else {
            return
        }
    }

    func getUsers(completion: @escaping([SearchUser]) -> Void) {
        db.collection("users").document(userId).collection("firstDegreeFriends").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var users = [SearchUser]()
                for document in querySnapshot!.documents {
                    let user = SearchUser()
                    user.uid = document.documentID
                    Firestore.firestore().collection("users").document(document.documentID).getDocument { (snapshot, error) in
                        if let dictionary = snapshot?.data() as? [String: AnyObject]{
                            user.username = dictionary["username"] as? String
                            user.firstName = dictionary["firstName"] as? String
                            user.lastName = dictionary["lastName"] as? String
                            user.profileUrl = dictionary["profileImageUrl"] as? String
                        }
                        completion(users)
                    }
                    users.append(user)
                }
                completion(users)
            }
        }
    }

    func addFriendIfNotAlreadyFriends(selfUID: String, friendUID: String) {
        let currentUserDocRef =  db.collection("users").document(selfUID);
        currentUserDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                let friendDocRef =  currentUserDocRef.collection("firstDegreeFriends").document(friendUID);
                friendDocRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        strongSelf.showNotification(title: ":)", body: "You've already added this friend.", response: "Okay")
                    } else {
                        strongSelf.addUserOneInfoToUserTwo(A: selfUID, B: friendUID);
                        strongSelf.showNotification(title: ":)", body: "Successfully sent request.", response: "Okay.")
                    }
                }
            } else {
                strongSelf.showNotification(title: ":(", body: "No user available.", response: "Okay")
            }
        }
    }

    func showNotification(title: String, body: String, response: String) {
        let alert = UIAlertController(title: title, message: body, preferredStyle: .alert)
        let okayAction = UIAlertAction(title:response, style: .default) { (action) in
        }
        alert.addAction(okayAction)
        present(alert, animated: true, completion: nil)
    }

    func addUserOneInfoToUserTwo(A: String, B: String) {
        let currentUserDocRef =  db.collection("users").document(A);
        let requestedDocRef =  db.collection("users").document(B);
        currentUserDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                currentUserDocRef.collection("sentRequests").document(B).setData(["uid":B])
            } else {
                strongSelf.showNotification(title: ":(", body: "No user A document available.", response: "Okay")
            }
        }
        requestedDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                requestedDocRef.collection("receivedRequests").document(A).setData(["uid":A])
            } else {
                strongSelf.showNotification(title: ":(", body: "No user B document available.", response: "Okay")
            }
        }
    }

    func snapShotListenerForBuzz() {
        listener1 = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
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
                    strongSelf.db.collection("users").document(strongSelf.userId).setData(["buzz" : 1], merge: true)
                    strongSelf.firstTime = false
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
        if listener1 != nil {
            listener1?.remove()
        }
    }

}
