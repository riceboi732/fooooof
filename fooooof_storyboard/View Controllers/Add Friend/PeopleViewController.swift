import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox

class PeopleViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, InvitationTableViewCellDelegate {

    func didTapButton(title: String, index: Int) {
        addFriendButtonTapped(friendUID: requestUsersUidArray[index])
        deleteRequest(friendUID: requestUsersUidArray[index])
        updateRequestsTable()
    }
    
    func didTapDeclineButton(index: Int) {
        deleteRequest(friendUID: requestUsersUidArray[index])
        updateRequestsTable()
    }
    
    @IBOutlet weak var tableView: UITableView!
    @IBAction func returnToHome(segue: UIStoryboardSegue){
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    @IBOutlet weak var quitButton: UIButton!
    

    var requestUsersUidArray = [String]()
    
    let db = Firestore.firestore()
    var listener1 : ListenerRegistration? = nil
    var firstTime = true
    var buzzIndicator = 1
    let userId = Auth.auth().currentUser!.uid
    let cellSpacingHeight: CGFloat = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.register(InvitationTableViewCell.nib(), forCellReuseIdentifier: InvitationTableViewCell.identifier)
        tableView.dataSource = self
        navigationController?.setNavigationBarHidden(true, animated: true)
        updateRequestsTable()
        quitButton.setTitle("", for:.normal)
        tableView.backgroundColor = UIColor.systemGray5
        tableView.rowHeight = 200
    }
    
    func updateRequestsTable() {
        getUsers() { [weak self] requestUids in
            guard let strongSelf = self else {
                return
            }
            strongSelf.requestUsersUidArray = requestUids
            strongSelf.tableView.reloadData()
        }
    }
    
    func deleteRequest(friendUID: String) {
        let selfUID = Auth.auth().currentUser!.uid
        let currentUserDocRef = db.collection("users").document(selfUID);
        currentUserDocRef.collection("receivedRequests").document(friendUID).delete() { err in
            if let err = err {
                print("Error removing received friend request: \(err)")
            } else {
                print("Received friend request successfully removed!")
            }
        }
        
        let friendUserDocRef = db.collection("users").document(friendUID);
        friendUserDocRef.collection("sentRequests").document(selfUID).delete() { err in
            if let err = err {
                print("Error removing sent friend request: \(err)")
            } else {
                print("Sent friend request successfully removed!")
            }
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if !requestUsersUidArray.isEmpty {
            return requestUsersUidArray.count
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: InvitationTableViewCell.identifier, for: indexPath) as! InvitationTableViewCell
        if !requestUsersUidArray.isEmpty {
//            getUserName(requestUid: requestUsersUidArray[indexPath.row]) { username in
//                cell.userNameText?.text =  username
//            }
            getFullName(requestUid: requestUsersUidArray[indexPath.row]) { fullName in
                cell.userNameText?.text =  fullName
            }
            getProfilePic(requestUid: requestUsersUidArray[indexPath.row]) { profileImageUrl in
                guard let url = URL(string: profileImageUrl) else { return }
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        if let originalImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                let image = Utilities.maskRoundedImage(image: originalImage, radius: min(originalImage.size.width, originalImage.size.height)/2)
                                var newSize: CGSize!
                                if min(image.size.width, image.size.height) <= 60 {
                                    newSize = CGSize(width: image.size.width, height: image.size.height)
                                    cell.profileImage.image = image
                                    cell.profileImage.frame.size = newSize
                                } else {
                                    let aspectRatio = image.size.width/image.size.height
                                    if aspectRatio > 1 {
                                            newSize = CGSize(width: 60 / aspectRatio, height: 60)
                                    } else {
                                            newSize = CGSize(width: 60, height: 60 * aspectRatio)
                                    }
                                    cell.profileImage.image = image
                                    cell.profileImage.frame.size = newSize
                                }
                            }
                        }
                    }
                }
            }
            //TODO: Change this to pending or add friend depending on friend status (write a function for that)
            cell.configure(title: "Accept", index: indexPath.row)
            cell.delegate = self
        }
        return cell
    }
    
    func getUserName(requestUid: String, completion: @escaping((String) -> Void)) {
            db.collection("users").document(requestUid).getDocument() {(snapshot, error) in
                let username = snapshot?.get("username") as? String
                completion(username ?? "default")
            }
    }
    
    func getFullName(requestUid: String, completion: @escaping((String) -> Void)) {
            self.db.collection("users").document(requestUid).getDocument() {(snapshot, error) in
                let firstName = snapshot?.get("firstName") as? String
                let lastName = snapshot?.get("lastName") as? String
                completion("\(firstName ?? "firstName") \(lastName ?? "lastName")" )
            }
    }
    
    func getProfilePic(requestUid: String, completion: @escaping((String) -> Void)) {
            db.collection("users").document(requestUid).getDocument() {(snapshot, error) in
                let profilePic = snapshot?.get("profileImageUrl") as? String
                completion(profilePic ?? "default")
            }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
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
    
    func getUsers(completion: @escaping([String]) -> Void) {
        let selfUID = Auth.auth().currentUser!.uid
        let currentUserDocRef = db.collection("users").document(selfUID);
        currentUserDocRef.collection("receivedRequests").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                var requestUids = [String]()
                for document in querySnapshot!.documents {
                    let requestUid = document.documentID
                    requestUids.append(requestUid)
                }
                completion(requestUids)
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
                        strongSelf.addUserOneInfoToUserTwo(A: friendUID, B: selfUID);
                        strongSelf.showNotification(title: ":)", body: "Successfully added a friend.", response: "Yay!")
                    }
                }
            } else {
                strongSelf.showNotification(title: ":(", body: "No user available.", response: "Okay")
            }
        }
    }
    
    func findFirstLastNames(uid: String, completion : @escaping ([String: String])->()){
        db.collection("users").document(uid).getDocument() { (snapshot, error) in
            let firstName = snapshot?.get("firstName")
            let lastName = snapshot?.get("lastName")
            var dataDict = [String: String]()
            dataDict["firstName"] = firstName as? String
            dataDict["lastName"] = lastName as? String
            completion(dataDict)
        }
    }
    
    func addFirstLastNames(selfUID: String, friendUid: String, friendFirstName: String, friendLastName: String) {
        let currentUserDocRef =  db.collection("users").document(selfUID);
        currentUserDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                currentUserDocRef.collection("firstDegreeFriends").document(friendUid).setData(["firstName": friendFirstName], merge: true)
                currentUserDocRef.collection("firstDegreeFriends").document(friendUid).setData(["lastName": friendLastName], merge: true)
            } else {
                print("unable to add first and last names")
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
        currentUserDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                strongSelf.addFriendToOthersSecondDegree(currentUserDocRef:currentUserDocRef, secondDegreeUid:B)
                currentUserDocRef.collection("firstDegreeFriends").document(B).setData(["uid":B], merge: true)
                strongSelf.findFirstLastNames(uid: B) { dataDict in
                    strongSelf.addFirstLastNames(selfUID: A, friendUid: B, friendFirstName: dataDict["firstName"] ?? "NoFirstName", friendLastName: dataDict["lastName"] ?? "NoLastName")
                }
                strongSelf.deleteFriendFromSecondDegree(currentUserDocRef:currentUserDocRef, secondDegreeUid:B)
            } else {
                strongSelf.showNotification(title: ":(", body: "No user A document available.", response: "Okay")
            }
        }
    }
    
    func addFriendToOthersSecondDegree(currentUserDocRef: DocumentReference, secondDegreeUid: String) {
        currentUserDocRef.collection("firstDegreeFriends").getDocuments() { [weak self] (querySnapshot, err) in
            guard let strongSelf = self else {
                return
            }
            if let err = err {
                print("Error getting firrstDegreeFriends documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    let firstDegreeFriendUid: String = document.data()["uid"]! as? String ?? ""
                    if firstDegreeFriendUid == secondDegreeUid
                    {
                        continue
                    }
                    let firstDegreeFriendDocRef =  strongSelf.db.collection("users").document(firstDegreeFriendUid)
                    strongSelf.checkFirstDegreeOrAddSecondDegree(firstDegreeFriendDocRef: firstDegreeFriendDocRef, secondDegreeUid: secondDegreeUid, firstDegreeFriendUid: firstDegreeFriendUid)
                }
            }
        }
    }
    
    func checkFirstDegreeOrAddSecondDegree(firstDegreeFriendDocRef: DocumentReference, secondDegreeUid: String, firstDegreeFriendUid: String) {
        firstDegreeFriendDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                let friendDocRef =  firstDegreeFriendDocRef.collection("firstDegreeFriends").document(secondDegreeUid)
                friendDocRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                    } else {
                        strongSelf.incrementSecondDegreeFriendCount(firstDegreeFriendDocRef: firstDegreeFriendDocRef, secondDegreeUid: secondDegreeUid, firstDegreeFriendUid: firstDegreeFriendUid)
                    }
                }
            } else {
                strongSelf.showNotification(title: ":(", body: "No first degree friend\n\(firstDegreeFriendUid) document available.", response: "Okay")
            }
        }
    }
    
    func incrementSecondDegreeFriendCount(firstDegreeFriendDocRef: DocumentReference, secondDegreeUid: String, firstDegreeFriendUid: String) {
        addUidBToFriendSecondDegree(firstDegreeFriendDocRef: firstDegreeFriendDocRef, secondDegreeUid: secondDegreeUid)
        addFriendsToUidBSecondDegree(firstDegreeFriendUid: firstDegreeFriendUid, secondDegreeUid: secondDegreeUid)
    }
    
    func addUidBToFriendSecondDegree(firstDegreeFriendDocRef: DocumentReference, secondDegreeUid: String) {
        let friendDocSecondDegreeRef =  firstDegreeFriendDocRef.collection("secondDegreeFriends").document(secondDegreeUid)
        friendDocSecondDegreeRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var firstDegreeFriendsConnectionCount = document.data()?["firstDegreeFriendsConnectionCount"]! as? Int ?? 0
                firstDegreeFriendsConnectionCount += 1
                friendDocSecondDegreeRef.setData(["firstDegreeFriendsConnectionCount": firstDegreeFriendsConnectionCount], merge: true)
            } else {
                friendDocSecondDegreeRef.setData(["firstDegreeFriendsConnectionCount":1], merge: true)
            }
        }
    }
    
    func addFriendsToUidBSecondDegree(firstDegreeFriendUid: String, secondDegreeUid: String) {
        let uidBDocRef =  db.collection("users").document(secondDegreeUid);
        uidBDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                let uidBSecondaryDocRef =  uidBDocRef.collection("secondDegreeFriends").document(firstDegreeFriendUid)
                strongSelf.uidBSecondDegreeIncrementCount(uidBSecondaryDocRef: uidBSecondaryDocRef)
            }
        }
    }
    
    func uidBSecondDegreeIncrementCount(uidBSecondaryDocRef: DocumentReference ) {
        uidBSecondaryDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                var firstDegreeFriendsConnectionCount = document.data()?["firstDegreeFriendsConnectionCount"]! as? Int ?? 0
                firstDegreeFriendsConnectionCount += 1
                uidBSecondaryDocRef.setData(["firstDegreeFriendsConnectionCount": firstDegreeFriendsConnectionCount], merge: true)
            } else {
                uidBSecondaryDocRef.setData(["firstDegreeFriendsConnectionCount": 1], merge: true)
            }
        }
    }
    
    func deleteFriendFromSecondDegree(currentUserDocRef: DocumentReference, secondDegreeUid: String) {
      currentUserDocRef.collection("secondDegreeFriends").document(secondDegreeUid).delete() { err in
        if let err = err {
          print("Error removing document: \(err)")
        }
        else {
          print("Document successfully removed!")
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
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return cellSpacingHeight
        }
}

