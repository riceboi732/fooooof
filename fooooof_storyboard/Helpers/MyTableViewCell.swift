import UIKit
import SDWebImage
import FirebaseFirestore

protocol MyTableViewCellDelegate: AnyObject {
    func didTapButton(title: String, index: Int)
}

class MyTableViewCell: UITableViewCell {
    
    weak var delegate: MyTableViewCellDelegate?

    static let identifier = "MyTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "MyTableViewCell", bundle: nil)
    }
    
    private var title: String = ""
    private var index: Int = 0
    
    //copied
    @IBOutlet weak var ProfilePic: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    private var name: String = ""
    private let db = Firestore.firestore()
    
    func configure(title: String, index: Int) {
        self.title = title
        self.index = index
        ProfilePic.layer.cornerRadius = ProfilePic.frame.height/2
        ProfilePic.clipsToBounds = true
    }
    
    //copied
    func findProfileImageUrl(uid: String, completion: @escaping ((String) -> Void)) {
        db.collection("users").document(uid).getDocument() { (snapshot, error) in
            if (snapshot?.get("profileImageUrl") != nil) {
                completion(snapshot?.get("profileImageUrl") as! String)
            }
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
}
