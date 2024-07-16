import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox

class SearchUserViewController: UIViewController, UISearchResultsUpdating, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIAdaptivePresentationControllerDelegate, MyTableViewCellDelegate {

    func didTapButton(title: String, index: Int) {
        //TODO: add chat function to this button, change title to chat instead of connect in mytableviewcell
        print("add chat function maybe")
    }

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var field: UITextField!
    @IBOutlet weak var backButton: UIButton!
    
    var usersArray = [SearchUser]()
    var filteredUsers = [SearchUser]()

    let db = Firestore.firestore()
    var listener1 : ListenerRegistration? = nil
    var firstTime = true
    var buzzIndicator = 1
    let userId = Auth.auth().currentUser!.uid
    
    var selectedFirstName: String?
    var selectedLastName: String?
    var selectedUsername: String?
    var selectedUid: String?
    var selectedMajor: String?
    var selectedCollege: String?
    var selectedClassYear: String?
    var selectedCompany: String?
    var selectedPositionAtCompany: String?
    var segued = "true"

    override func viewDidLoad() {
        super.viewDidLoad()
        segued = "false"
        tableView.layoutMargins = UIEdgeInsets.zero
        tableView.separatorInset = UIEdgeInsets.zero
        backButton.setTitle("", for: .normal)
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

    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if let text = textField.text {
            if string.isEmpty
            {
                let endIndex = text.count-1
                print("\(endIndex)")
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
            cell.friendName?.text = filteredUsers[indexPath.row].getName()
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
        //call full profile for the selected user
        let targetUserData = filteredUsers[indexPath.row]
        var friendUid = targetUserData.getUid()
        showUserInfo(uid: friendUid) { [weak self] dataDict in
            guard let strongSelf = self else {
                return
            }
            strongSelf.selectedFirstName = dataDict["firstName"]
            strongSelf.selectedLastName = dataDict["lastName"]
            strongSelf.selectedUsername = dataDict["username"]
            strongSelf.selectedUid = dataDict["uid"]
            strongSelf.selectedMajor = dataDict["major"]
            strongSelf.selectedCollege = dataDict["college"]
            strongSelf.selectedClassYear = dataDict["classYear"]
            strongSelf.selectedCompany = dataDict["company"]
            strongSelf.selectedPositionAtCompany = dataDict["position"]
            let notificationNameFull = Notification.Name(rawValue: fullProfileNotificationKey)
            let notificationCenter = NotificationCenter.default
            NotificationCenter.default.post(name: notificationNameFull, object: nil, userInfo: dataDict)
            if strongSelf.segued == "false" {
                strongSelf.performSegue(withIdentifier: "ShowFullProfile", sender: nil)
                strongSelf.segued = "true"
            }
        }
    }
    
    func showUserInfo(uid: String, completion: @escaping ([String: String]) -> ()) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                var dataDict = [String: String]()
                let firstName = document.get("firstName")
                let lastName = document.get("lastName")
                let username = document.get("username")
                let profileImageUrl = document.get("profileImageUrl")
                let major = document.get("major")
                let college = document.get("college")
                let classYear = document.get("classYear")
                let company = document.get("company")
                let positionAtCompany = document.get("position")
                
                dataDict["firstName"] = firstName as? String
                dataDict["lastName"] = lastName as? String
                dataDict["username"] = username as? String
                dataDict["profileImageUrl"] = profileImageUrl as? String
                dataDict["uid"] = uid
                dataDict["major"] = major as? String
                dataDict["college"] = college as? String
                dataDict["classYear"] = classYear as? String
                dataDict["company"] = company as? String
                dataDict["position"] = positionAtCompany as? String
                strongSelf.findFriends(A: strongSelf.userId) {nameSetA in
                    strongSelf.findFriends(A: uid) { nameSetB in
                        let commonFriends = Set(nameSetA).intersection(Set(nameSetB))
                        var commonFriendsString = ""
                        let friendCount = commonFriends.count
                        for friend in commonFriends {
                            if commonFriendsString.isEmpty {
                                if friendCount == 1 {
                                    commonFriendsString += "\(commonFriends.count) " +
                                    "Mutual Connection: \(friend)"
                                } else {
                                    commonFriendsString += "\(commonFriends.count) " +
                                    "Mutual Connections: \(friend)"
                                }
                            } else {
                                commonFriendsString += ", \(friend)"
                            }
                        }
                        dataDict["commonFriends"] = commonFriendsString
                        UserDefaults.standard.set(commonFriendsString, forKey: "commonFriends")
                        completion(dataDict)
                    }
                }
                strongSelf.findFriendsPFP(PFP: strongSelf.userId) {pfpSetA in
                    strongSelf.findFriendsPFP(PFP: uid) { pfpSetB in
                        let commonFriendsPFP = Set(pfpSetA).intersection(Set(pfpSetB))
                        var commonFriendsStringPFP = ""
                        let friendCountPFP = commonFriendsPFP.count
                        for friend in commonFriendsPFP {
                            if commonFriendsStringPFP.isEmpty {
                                if friendCountPFP == 1 {
                                    commonFriendsStringPFP += "\(friend)"
                                } else {
                                    commonFriendsStringPFP += "\(friend)"
                                }
                            } else {
                                commonFriendsStringPFP += "\(friend)"
                            }
                        }
                        dataDict["commonFriendsPFP"] = commonFriendsStringPFP
                        UserDefaults.standard.set(commonFriendsStringPFP, forKey: "commonFriendsPFP")
                        completion(dataDict)
                    }
                }
            } else {
                print("User on map document does not exist")
            }
        }
    }
    
    func findFriends(A: String, completion: @escaping (Set<String>) -> ()) {
        var friendListA = Set<String>()
        let db = Firestore.firestore()
        let docRef =  db.collection("users").document(A);
        docRef.collection("firstDegreeFriends")
            .getDocuments { [weak self] querySnapshot, err in
                guard let strongSelf = self else {
                    return
                }
                if let err = err {
                    print ("Error getting documents: \(err)")
                } else {
                    let numDocs = querySnapshot?.count
                    var processedDocs = 0
                    for document in
                            querySnapshot!.documents {
                        strongSelf.getName(uid: document.documentID) { name in
                            friendListA.insert(name)
                            processedDocs = processedDocs + 1
                            if processedDocs == numDocs {
                                completion(friendListA)
                            }
                        }
                    }
                }
            }
    }
    
    func findFriendsPFP(PFP: String, completion: @escaping (Set<String>) -> ()) {
        var friendListPFP = Set<String>()
        let db = Firestore.firestore()
        let docRef =  db.collection("users").document(PFP);
        docRef.collection("firstDegreeFriends")
            .getDocuments { [weak self] querySnapshot, err in
                guard let strongSelf = self else {
                    return
                }
                if let err = err {
                    print ("Error getting documents: \(err)")
                } else {
                    let numDocs = querySnapshot?.count
                    var processedDocsPFP = 0
                    for document in
                            querySnapshot!.documents {
                        strongSelf.getPfp(uid: document.documentID) { pfpURL in
                            friendListPFP.insert(pfpURL)
                            processedDocsPFP = processedDocsPFP + 1
                            if processedDocsPFP == numDocs {
                                completion(friendListPFP)
                            }
                        }
                    }
                }
            }
    }
    
    func getPfp(uid: String, completion: @escaping (String)->()) {
        let db = Firestore.firestore()
        let docRef =  db.collection("users").document(uid);
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var pfpURL = document.data()?["profileImageUrl"]! as? String ?? "noPfpURL"
                pfpURL += " "
                completion(pfpURL)
            } else {
                completion("nothing")
            }
        }
    }
    
    func getName(uid: String, completion: @escaping (String)->()) {
        let db = Firestore.firestore()
        let docRef =  db.collection("users").document(uid);
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var name = document.data()?["firstName"]! as? String ?? "noFirstName"
                name += " "
                name += document.data()?["lastName"]! as? String ?? "noLastName"
                completion(name)
            } else {
                completion("nothing")
            }
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ShowFullProfile" {
            segue.destination.presentationController?.delegate = self
            let controller = segue.destination as! FullProfileViewController
            controller.selectedFirstName = selectedFirstName ?? ""
            controller.selectedUsername = selectedUsername ?? ""
            controller.selectedLastName = selectedLastName ?? ""
            controller.selectedUid = selectedUid ?? ""
            controller.selectedMajor = selectedMajor ?? ""
            controller.selectedCollege = selectedCollege ?? ""
            controller.selectedClassYear = selectedClassYear ?? ""
            controller.selectedCompany = selectedCompany ?? ""
            controller.selectedPositionAtCompany = selectedPositionAtCompany ?? ""
            controller.view.isUserInteractionEnabled = true
        }
    }
    
    public func presentationControllerDidDismiss(
        _ presentationController: UIPresentationController)
      {
          segued = "false"
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
