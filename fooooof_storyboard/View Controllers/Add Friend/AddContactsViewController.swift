import Contacts
import MessageUI
import ContactsUI
import UIKit
import Firebase
import  FirebaseAuth

class AddContactsViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, ContactsTableViewCellDelegate, MFMessageComposeViewControllerDelegate {
    
    
    @IBOutlet weak var homeButton: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    // Property to store the contacts that you'll be displaying in the table view
    var contacts = [CNContact]()
    //TODO: Rank contacts, get rid of contacts that are already friends
    let db = Firestore.firestore()
    let selfUID = Auth.auth().currentUser!.uid
    var selfNumber = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getSelfNumber() { [weak self] number in
            guard let strongSelf = self else {
                return
            }
            strongSelf.selfNumber = number
            strongSelf.homeButton.setTitle("", for: .normal)
            strongSelf.tableView.dataSource = self
            strongSelf.tableView.delegate = self
            strongSelf.tableView.register(ContactsTableViewCell.nib(), forCellReuseIdentifier: ContactsTableViewCell.identifier)
            // Request access to the user's contacts
            CNContactStore().requestAccess(for: .contacts) { (granted, error) in
                if granted {
                    // Fetch the user's contacts
                    let keysToFetch = [CNContactGivenNameKey, CNContactFamilyNameKey, CNContactPhoneNumbersKey]
                    let request = CNContactFetchRequest(keysToFetch: keysToFetch as [CNKeyDescriptor])
                    request.sortOrder = CNContactsUserDefaults.shared().sortOrder
                    try! CNContactStore().enumerateContacts(with: request) { (contact, stop) in
    //                    print("Printing for filtering later: \(contact.givenName)")
                        let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
                        print("selfNumber is \(strongSelf.selfNumber)")
                        var changeNumber = phoneNumber
                            .replacingOccurrences(of: " ", with: "")
                            .replacingOccurrences(of: "(", with: "")
                            .replacingOccurrences(of: ")", with: "")
                            .replacingOccurrences(of: "-", with: "")
                            .replacingOccurrences(of: "+1", with: "")
                        changeNumber = "+1\(changeNumber)"
                        print("Changenumber is \(changeNumber)")
                        if contact.givenName != "" && contact.familyName != "" && phoneNumber != "" && strongSelf.selfNumber != changeNumber{
                            strongSelf.contacts.append(contact)
                        }
                    }
                    
                    // Reload the table view
                    DispatchQueue.main.async {
                        strongSelf.tableView.reloadData()
                    }
                }
            }
        }
    }
    
    func getSelfNumber(completion: @escaping((String) -> Void)) {
        let currentUserDocRef =  db.collection("users").document(selfUID);
        currentUserDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                completion(document.data()?["phone"] as! String)
            } else {
                print("current user document doesn't exist")
                completion("")
            }
        }
    }
    
    //TODO: fix this
    func didTapButton(title: String, index: Int) {
        //TODO: add add friend function
        print("add friend function")
        print("index is \(index)")
        let contact = contacts[index]
        let indexPath = IndexPath(row: index, section: 0)
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsTableViewCell.identifier, for: indexPath) as! ContactsTableViewCell
        //TODO: check that the user has a number
        let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
        print("\(contact.givenName) \(contact.familyName) \(phoneNumber)")
        //userExists returns as the phoneNumber's corresponding uid if found in fooooof user database
        checkUserExists(phoneNumber: phoneNumber) { [weak self] userExists in
            guard let strongSelf = self else {
                return
            }
            if userExists == "false" {
                guard MFMessageComposeViewController.canSendText() else {
                    print("Device is not able to send messages")
                    return
                }
                
                let composer = MFMessageComposeViewController()
                composer.messageComposeDelegate = self
                composer.recipients = ["\(phoneNumber)"]
                composer.body = "Download fooooof on the app store!"
                strongSelf.present(composer, animated: true)
            } else {
                strongSelf.isFirstDegreeFriend(friendUID: userExists) { isFirstDegreeFriend in
                    if isFirstDegreeFriend == "false" {
                        //TODO: send connect invitation for friendUID = userExists
                        strongSelf.addUserOneInfoToUserTwo(A: strongSelf.selfUID, B: userExists)
                        strongSelf.showNotification(title: ":)", body: "Friend Request Sent", response: "Yay!")
                    } else {
                        //TODO: send to message page (dead button for now)
                        strongSelf.showNotification(title: "In progress", body: "We're still developing this feature :)", response: "Okay")
                    }
                }
                //TODO: print out uni. write connect function / chat function
                //userExists returns the uni of the person
                print("found user check function")
                //check if user is already friend, if yes, delete from data array and reload table
                //https://stackoverflow.com/questions/34523352/how-do-i-programmatically-delete-row-0-of-uitableview
            }
        }
        
    }
    
    func messageComposeViewController(_ controller: MFMessageComposeViewController, didFinishWith result: MessageComposeResult) {
        switch result {
        case .cancelled:
            print("Cancelled")
        case .failed:
            print("Failed")
        case .sent:
            print("Sent")
        default:
            print("Unknown")
        }
        controller.dismiss(animated: true)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of contacts
        return contacts.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ContactsTableViewCell.identifier, for: indexPath) as! ContactsTableViewCell
        // Configure the cell with the contact's name
        let contact = contacts[indexPath.row]
        cell.textLabel?.text = "\(contact.givenName) \(contact.familyName)"
        cell.configure(title: "Invite", index: indexPath.row)
        
        let phoneNumber = contact.phoneNumbers.first?.value.stringValue ?? ""
        checkUserExists(phoneNumber: phoneNumber) { [weak self] userExists in
            guard let strongSelf = self else {
                return
            }
            if userExists == "false" {
                cell.setButton(title: "Invite")
            } else {
                strongSelf.isFirstDegreeFriend(friendUID: userExists) { isFirstDegreeFriend in
                    if isFirstDegreeFriend == "false" {
                        cell.setButton(title: "Connect")
                    } else {
                        cell.setButton(title: "Message")
                    }
                }
            }
        }
        
//        cell.setButton(title: "")
        cell.delegate = self
        return cell
    }
    
    func checkUserExists(phoneNumber: String, completion: @escaping((String) -> Void)) {
        //check phone number isn't empty
        if phoneNumber == "" {
            completion("false")
        } else {
            //convert phone number from (xxx) xxx-xxxx to +1xxxxxxxxxx
            var changeNumber = phoneNumber
                .replacingOccurrences(of: " ", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
                .replacingOccurrences(of: "-", with: "")
                .replacingOccurrences(of: "+1", with: "")
            changeNumber = "+1\(changeNumber)"
            let docRef = db.collection("users").whereField("phone", isEqualTo: changeNumber).limit(to: 1)

            docRef.getDocuments{ (querysnapshot, error) in
                if error != nil {
                    print("Document Error: ", error!)
                } else if let doc = querysnapshot?.documents, !doc.isEmpty {
                    //not empty, found user, returns uid of the person
                    completion("\(doc[0].data()["uid"] as! String)")
                } else {
                    //did not find user
                    completion("false")
                }
            }
            //see if it exists in firebase and return
        }
    }
    
    func isFirstDegreeFriend(friendUID: String, completion: @escaping((String) -> Void)) {
        let currentUserDocRef =  db.collection("users").document(selfUID);
        currentUserDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let friendDocRef =  currentUserDocRef.collection("firstDegreeFriends").document(friendUID);
                friendDocRef.getDocument { (document, error) in
                    if let document = document, document.exists {
                        completion("true")
                    } else {
                        completion("false")
                    }
                }
            } else {
                completion("current user document doesn't exist")
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

}
