import Foundation
import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore
import AudioToolbox

class AddFriendViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var myTable1: UITableView!
    let db = Firestore.firestore()
    var friends = [(String, String)]()
    let user = Auth.auth().currentUser
    let userId = Auth.auth().currentUser!.uid
    var userName = ""
    var listener : ListenerRegistration? = nil
    var listener1 : ListenerRegistration? = nil
    var firstTime1 = true
    var buzzIndicator = 1
    @IBAction func returnToHome(segue: UIStoryboardSegue){
        let homeViewController = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.homeViewController) as? HomeViewController
        view.window?.rootViewController = homeViewController
        view.window?.makeKeyAndVisible()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.myTable1.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        self.myTable1.delegate = self
        self.myTable1.dataSource = self
        creatFriendPage(myUid: userId)
        snapShotListenerForBuzz()
        getUserName()
    }
    
    func getUserName() {
        db.collection("users").document(userId).getDocument() {(snapshot, error) in
            self.userName = snapshot?.get("firstName") as! String
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friends.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = friends[indexPath.row].1
     
        cell.accessoryType = .disclosureIndicator
        return cell
    }



    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
//        let vc = Chat1ViewController()
//        vc.userName = self.userName
//        vc.title = friends[indexPath.row].1
//        vc.friendName = friends[indexPath.row].1
//        vc.userId = userId
//        vc.friendId = friends[indexPath.row].0
//        setAvatarPic(userId, friends[indexPath.row].0, vc) { () in
//            self.navigationController?.isNavigationBarHidden = false
//            self.navigationController?.pushViewController(vc, animated: true)
//        }
    }
    
    
//    func setAvatarPic(_ userId: String, _ friendId: String, _ vc: Chat1ViewController, completion: @escaping ()->()) {
//        db.collection("users").document(userId).getDocument() { (snapshot, error) in
//            if (snapshot?.get("profileImageUrl") != nil) {
//                vc.myImageUrl = URL(string: snapshot?.get("profileImageUrl") as! String)
//                self.db.collection("users").document(friendId).getDocument() { (snapshot1, error) in
//                    if (snapshot?.get("profileImageUrl") != nil) {
//                        vc.friendImageUrl = URL(string: snapshot1?.get("profileImageUrl") as! String)
//                        completion()
//                    } else {
//                        print(snapshot?.get("profileImageUrl") as Any)
//                    }
//                    
//                }
//            } else {
//                print(snapshot?.get("profileImageUrl") as Any)
//            }
//        }
//        
//    }
    
    
    func creatFriendPage(myUid: String){
        initialiseFriends(myUid: myUid) { () in
            self.myTable1.reloadData()
        }
        //might have add the last chatroom twice
        self.listener = self.db.collection("users").document(myUid).collection("firstDegreeFriends").addSnapshotListener { snapshot, error in
            switch (snapshot, error) {
                    case (.none, .none):
                        print("no data")
                    case (.none, .some(let error)):
                        print("some error \(error.localizedDescription)")
                    case (.some(_), _):
                        self.initialiseFriends(myUid: myUid) { () in
                            self.myTable1.reloadData()
                }
            }
        }
    }

    func initialiseFriends(myUid: String, completion: @escaping ()->()){
        let friendPage = db.collection("users").document(myUid).collection("firstDegreeFriends")
        friendPage.getDocuments() {(snapshots, error) in
            if let error = error {
                print("Error getting documents: \(error)")
            } else {
                self.friends = []
                for document in snapshots!.documents {
                    let id = document.data()["uid"] as! String
                    let friend = self.db.collection("users").document(id)
                    var name = ""
                    if document.data()["firstName"] as? String == nil || document.data()["lastName"] as? String == nil {
                         friend.getDocument() { (snapshot, error) in
                            let firstName = snapshot?.data()?["firstName"] as! String
                            let lastName = snapshot?.data()?["lastName"] as! String
                            name = firstName + " " + lastName
                            if self.friends.count == 0 {
                                self.friends.append((id,name))
                                completion()
                            } else if id != self.friends[self.friends.count - 1].0 {
                                self.friends.append((id,name))
                                completion()
                            }
                            friendPage.document(id).setData(["firstName" : firstName, "lastName": lastName], merge: true)
                         }
                    } else {
                        name = document.data()["firstName"] as! String
                        name += " "
                        name += document.data()["lastName"] as! String
                        if self.friends.count == 0 {
                            self.friends.append((id,name))
                        } else if id != self.friends[self.friends.count - 1].0 {
                            self.friends.append((id,name))
                        }
                    }
                }
                completion()
            }
        }
        
    }

    func snapShotListenerForBuzz() {
        self.listener1 = self.db.collection("users").document(userId).addSnapshotListener { snapshot, error in
            switch (snapshot, error) {
                    case (.none, .none):
                        print("no data")
                    case (.none, .some(let error)):
                        print("some error \(error.localizedDescription)")
                    case (.some(_), _):
                        if self.firstTime1 == true {
                            self.buzzIndicator = 1
                            self.db.collection("users").document(self.userId).setData(["buzz" : 1], merge: true)
                            self.firstTime1 = false
                        } else {
                            if snapshot?.get("buzz") as! Int != self.buzzIndicator {
                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
                                self.buzzIndicator = snapshot?.get("buzz") as! Int
                            }
                        }
            }
        }
    }

    func onAppIndication(_ userId: String) {
        self.db.collection("users").document(userId).setData(["onApp":1],merge: true)
    }

    func offAppIndication(_ userId: String) {
        self.db.collection("users").document(userId).setData(["onApp":0],merge: true)
    }

    override func viewDidDisappear(_ animated: Bool) {
        if listener != nil {
            listener?.remove()
        }
        if listener1 != nil {
            listener1?.remove()
        }
    }
}

