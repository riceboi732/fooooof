import Foundation
import UIKit
import FirebaseFirestore
import FirebaseAuth
import AudioToolbox

let usernameFoundNotificationKey = "com.fooooof.usernameFoundNotificationKey"

class UsernameFoundViewController: UIViewController, UITextFieldDelegate {
    
    @IBOutlet weak var quitButton: UIButton!
    
    @IBOutlet weak var username: UILabel!
    
    @IBOutlet weak var profileImage: UIImageView!
    
    @IBOutlet weak var addFriendButton: UIButton!
    
    @IBOutlet weak var greyButton: UIButton!
    
    @IBOutlet weak var fullName: UILabel!
    
    let db = Firestore.firestore()
    let userId = Auth.auth().currentUser!.uid
    var friendUID = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if UserDefaults.standard.string(forKey: "foundUsername") != nil{
            let foundUsername = UserDefaults.standard.string(forKey: "foundUsername")!
            username.text = foundUsername
            UserDefaults.standard.removeObject(forKey: "foundUsername")
        }
        if UserDefaults.standard.string(forKey: "foundFullName") != nil{
            let foundFullName = UserDefaults.standard.string(forKey: "foundFullName")!
            fullName.text = foundFullName
            UserDefaults.standard.removeObject(forKey: "foundFullName")
        }
        if UserDefaults.standard.string(forKey: "profileImageUrl") != nil{
            let profileImageUrl = UserDefaults.standard.string(forKey: "profileImageUrl")!
            addProfile(profileImageUrl: profileImageUrl)
            UserDefaults.standard.removeObject(forKey: "profileImageUrl")
        }
        if UserDefaults.standard.string(forKey: "friendUid") != nil{
            friendUID = UserDefaults.standard.string(forKey: "friendUid")!
            UserDefaults.standard.removeObject(forKey: "friendUid")
        }
        quitButton.setTitle("", for: .normal)
        if (friendUID == userId) {
            hideFriendButton()
        } else {
            isFriend()
        }
    }
    
    func hideFriendButton() {
        addFriendButton.alpha = 0
        greyButton.alpha = 0
    }
    
    func isFriend() {
        let selfUID = userId
        let currentUserDocRef =  db.collection("users").document(selfUID);
        currentUserDocRef.getDocument { [weak self] (document, error) in
            guard let strongSelf = self else {
                return
            }
            if let document = document, document.exists {
                let friendDocRef =  currentUserDocRef.collection("firstDegreeFriends").document(strongSelf.friendUID);
                friendDocRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        strongSelf.addAlreadyFriendUIFunction(text: "Already added friend")
                        //else if in requested
                        //
                    } else {
                        let pendingDocRef =  currentUserDocRef.collection("sentRequests").document(strongSelf.friendUID);
                        pendingDocRef.getDocument { (document1, error) in
                            if let document1 = document1, document1.exists {
//                                print("PENDINGPENDIN")
                                strongSelf.addAlreadyFriendUIFunction(text: "Pending")
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
    
    @IBAction func addFriend(_ sender: Any) {
        addAlreadyFriendUIFunction(text: "pending")
        addUserOneInfoToUserTwo(A: userId, B: friendUID);
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
    
    func addAlreadyFriendUIFunction(text: String) {
        print("alreadyFriends")
        //show greybutton
//        self.addFriendButton.tintColor = UIColor.lightGray
//        self.addFriendButton.backgroundColor = UIColor.lightGray
        addFriendButton.alpha = 0
        greyButton.alpha = 1
        greyButton.setTitle(text, for: .normal)
        //TODO: change button background to light gray, and text to already friends
        //get rid of existing functions on button
    }
    
    func addNotFriendFunction() {
        print("notFriends")
        addFriendButton.alpha = 1
        greyButton.alpha = 0
        //TODO: add function to button to add friend
        //then change to addalreadyfriendjuifunction
        //pending & get rid of existing functions on button
    }
    
    //if clicked on addnotfriendfunction
    //self.addAlreadyFriendUIFunction(text: "Pending")
    
    func addProfile(profileImageUrl: String) {
        guard let url = URL(string: profileImageUrl) else { return }
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url) {
                if let originalImage = UIImage(data: data) {
                    DispatchQueue.main.async {
                        let image = Utilities.maskRoundedImage(image: originalImage, radius: min(originalImage.size.width, originalImage.size.height)/2)
                        var newSize: CGSize!
                        if min(image.size.width, image.size.height) <= 100 {
                            newSize = CGSize(width: image.size.width, height: image.size.height)
                            self.profileImage.image = image
                            self.profileImage.frame.size = newSize
                        } else {
                            let aspectRatio = image.size.width/image.size.height
                            if aspectRatio > 1 {
                                newSize = CGSize(width: 100 / aspectRatio, height: 100)
                            } else {
                                newSize = CGSize(width: 100, height: 100 * aspectRatio)
                            }
                            self.profileImage.image = image
                            self.profileImage.frame.size = newSize
                        }
                    }
                }
            }
        }
    }
}
