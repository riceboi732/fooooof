import Foundation
import UIKit
import FirebaseAuth
import Firebase
import FirebaseFirestore

class Block {
    
    var selectedUid = ""
    let selfUid = Auth.auth().currentUser!.uid
    
    static func addToBlockList(blockerUid: String, blockedUid: String, db: Firestore) {
        let docData: [String: Any] = [
            blockedUid: true
        ]
        db.collection("blocked").document(blockerUid).setData(docData, merge: true) { err in
            if let err = err {
                print("Error adding \(blockedUid) to blocked list: \(err)")
            } else {
                print("\(blockedUid) successfully blocked!")
            }
        }
    }
    
    static func unfriendButtonPressed(selectedUid: String, selfUid: String, db: Firestore, completion: @escaping (Bool) -> Void) {
        deleteRelatedSecondDegrees(otherUid: selectedUid, selfUid: selfUid, db: db)
        deleteRelatedSecondDegrees(otherUid: selfUid, selfUid: selectedUid, db: db)
        deleteFriendFromFirstDegree(otherUid: selectedUid, selfUid: selfUid, db: db)
        deleteFriendFromFirstDegree(otherUid: selfUid, selfUid: selectedUid, db: db)
        completion(true)
    }
    
    static func deleteRelatedSecondDegrees(otherUid: String, selfUid: String, db: Firestore) {
        print("starting delete related second degrees")
        db.collection("users").document(otherUid).collection("firstDegreeFriends").getDocuments() { (querySnapshot, err) in
            print("testing 1")
            if let err = err {
                print("testing 2")
                print("Error getting documents: \(err)")
            } else {
                print("did it successfully get snapshots?")
                for document in querySnapshot!.documents {
                    print("trying to see if can delete \(otherUid) from collection")
                    let documentId = document.documentID
                    deleteOtherFromMySecondDegree(selfUid: selfUid, otherUid: documentId, db: db)
                    deleteOtherFromMySecondDegree(selfUid: documentId, otherUid: selfUid, db: db)
                }
            }
        }
    }
    
    static func deleteOtherFromMySecondDegree(selfUid: String, otherUid: String, db: Firestore) {
        print("going into the deletion from second degree function")
        let docRef = db.collection("users").document(selfUid).collection("secondDegreeFriends").document(otherUid)
        docRef.getDocument {(document, error) in
            if let document = document {
                if document.exists{
                    print("second degree person exists")
                    secondDegreeDecrementCount(document: document, docRef: docRef, documentId: otherUid)
                } else {
                    print("Weird...their first degree friend is not our second degree")
                }
            }
        }
    }
    
    static func secondDegreeDecrementCount(document: DocumentSnapshot, docRef: DocumentReference, documentId: String) {
        var firstDegreeFriendsConnectionCount = document.data()?["firstDegreeFriendsConnectionCount"]! as? Int ?? 0
        if firstDegreeFriendsConnectionCount > 1 {
            print("only decrementing second degree friend count")
            firstDegreeFriendsConnectionCount -= 1
            docRef.setData(["firstDegreeFriendsConnectionCount": firstDegreeFriendsConnectionCount], merge: true)
            print("Successfully decremented \(documentId) from firstDegreeFriendsConnectionCount!")
        } else {
            docRef.delete() { err in
                print("deleting secondary friend because count = 1")
                if let err = err {
                    print("Error removing \(documentId) from firstDegreeFriendsConnectionCount: \(err)")
                } else {
                    print("Successfully removed \(documentId) from firstDegreeFriendsConnectionCount!")
                }
            }
        }
    }
    
    static func deleteFriendFromFirstDegree(otherUid: String, selfUid: String, db: Firestore) {
        db.collection("users").document(selfUid).collection("firstDegreeFriends").document(otherUid).delete() { err in
            if let err = err {
                print("Error removing \(otherUid) from firstDegreeFriends: \(err)")
            } else {
                print("Successfully removed \(otherUid) from firstDegreeFriends!")
            }
        }
    }
}
