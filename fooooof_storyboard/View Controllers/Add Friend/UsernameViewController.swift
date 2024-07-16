import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox

class UsernameViewController: UIViewController, UITextFieldDelegate, UIAdaptivePresentationControllerDelegate {
    
    @IBOutlet weak var quitButton: UIButton!
    @IBOutlet weak var textField: UITextField!
    
    let db = Firestore.firestore()
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
        segued = "false"
        super.viewDidLoad()
        quitButton.setTitle("", for: .normal)
        textField.layer.cornerRadius = 25.0
        textField.layer.borderWidth = 1.0
        textField.layer.borderColor = UIColor.red.cgColor
        textField.layer.masksToBounds = true
        textField.attributedPlaceholder = NSAttributedString(string:"Username", attributes:[NSAttributedString.Key.foregroundColor: UIColor(named:"fooooofRed")!])
        textField.becomeFirstResponder()
        textField.delegate = self
        textField.autocorrectionType = .no
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == textField {
            textField.resignFirstResponder()
            var username:String = textField.text?.lowercased() ?? ""
            searchUsernameInDB(username: username)
            print(username)
            return false
        }
        return true
    }
    
    func searchUsernameInDB(username: String) {
        
        db.collection("users").whereField("username", isEqualTo: username)
            .getDocuments() { [weak self] (querySnapshot, err) in
                guard let strongSelf = self else {
                    return
                }
                if let err = err {
                    print("Error getting documents: \(err)")
                } else if (querySnapshot!.documents.count == 0){
                    print("no username")
                    strongSelf.performSegue(withIdentifier: "NoUserFound", sender: self)
                } else {
                    for document in querySnapshot!.documents {
                        var friendUid = document.get("uid") as! String
                        print("The friend's uid of username \(username) is \(friendUid)")
                        strongSelf.showUserInfo(uid: friendUid) { [weak self] dataDict in
                            print("after showUserInfo called")
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
                            print("trying to segue")
                            if strongSelf.segued == "false" {
                                print("not yet segued")
                                strongSelf.performSegue(withIdentifier: "UsernameFoundFull", sender: nil)
                                strongSelf.segued = "true"
                            }
                        }
                    }
                }
            }
    }
    
    func showUserInfo(uid: String, completion: @escaping ([String: String]) -> ()) {
        print("is it showing user info?")
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        docRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            print("is it showing user info 2?")
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
                print("is it showing user info 3?")
                strongSelf.findFriends(A: strongSelf.userId) {nameSetA in
                    print("is it showing user info 4?")
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
        print("is it showing user info 5?")
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
                    print("is it showing user info 6?")
                    if(numDocs == 0) {
                        completion(friendListA)
                    }
                    for document in
                            querySnapshot!.documents {
                        print("is it showing user info 7?")
                        strongSelf.getName(uid: document.documentID) { name in
                            print("is it showing user info 7?")
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
        print("is it showing user info 8?")
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
        if segue.identifier == "UsernameFoundFull" {
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
    
}
