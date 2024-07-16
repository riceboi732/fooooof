import UIKit
import SDWebImage
import FirebaseFirestore

class ChatroomTableViewCell: UITableViewCell {

    static let identifier = "ChatroomTableViewCell"
    
    static func nib() -> UINib {
        return UINib(nibName: "ChatroomTableViewCell", bundle: nil)
    }
    
    @IBOutlet weak var time: UILabel!
    @IBOutlet weak var ProfilePic: UIImageView!
    @IBOutlet weak var friendName: UILabel!
    @IBOutlet weak var lastMessage: UILabel!
    private var name: String = ""
    private var message: String = ""
    private let db = Firestore.firestore()
    
    public func configure(with model: Conversation) {
        lastMessage.text = model.latestMessage.text
        friendName.text = model.name
        findProfileImageUrl(uid: model.otherUserUid) { [weak self] urlString in
            guard let strongSelf = self else {
                return
            }
            DispatchQueue.main.async {
//                print("The user profile image for \(model.name) is: \(urlString)")
                strongSelf.ProfilePic.sd_setImage(with: URL(string: urlString))
                strongSelf.ProfilePic.layer.cornerRadius = strongSelf.ProfilePic.frame.height/2
                strongSelf.ProfilePic.clipsToBounds = true
            }
        }
    }

    func findProfileImageUrl(uid: String, completion: @escaping ((String) -> Void)) {
        db.collection("users").document(uid).getDocument() { (snapshot, error) in
            if (snapshot?.get("profileImageUrl") != nil) {
                completion(snapshot?.get("profileImageUrl") as! String)
            }
        }
    }
    
//    func configure(name: String, message: String, url: URL?, time1: Date) {
//        self.name = name
//        self.message = message
//        friendName.text = name
//        lastMessage.text = message
//        if url != nil {
//            ProfilePic.load(url: url!
//            ProfilePic.sd_setImage(with: url)
//            ProfilePic.layer.cornerRadius = ProfilePic.frame.height / 2.0
//            ProfilePic.layer.masksToBounds = true
//        }
//        let dateFormatter = DateFormatter()
//        dateFormatter.timeZone = TimeZone.current
//        let date1 = time1
//        let date2 = Date()
//        dateFormatter.dateFormat = "yyyy"
//        let year11 = dateFormatter.string(from: date1)
//        let year22 = dateFormatter.string(from: date2)
//        let start = Calendar.current.startOfDay(for: date1)
//        let end = Calendar.current.startOfDay(for: date2)
//        let date11 = Calendar.current.date(byAdding: .day, value: 6, to: date1)!
//        let date22 = Calendar.current.date(byAdding: .day, value: 6, to: date2)!
//        let nextWeekend1 = Calendar.current.nextWeekend(startingAfter: date11)
//        let nextWeekend2 = Calendar.current.nextWeekend(startingAfter: date22)
//        let components = Calendar.current.dateComponents([.day], from: start, to: end)
//        if components.day == 0 {
//            dateFormatter.dateFormat = "HH:mm"
//            time.text = dateFormatter.string(from: date1)
//        } else if components.day == 1 {
//            time.text = "yesterday"
//        } else if nextWeekend1 == nextWeekend2 {
//            dateFormatter.dateFormat = "E"
//            time.text = dateFormatter.string(from: date1)
//        } else if year11 == year22 {
//            dateFormatter.dateFormat = "MMM d"
//            time.text = dateFormatter.string(from: date1)
//        } else {
//            dateFormatter.dateFormat = "MMM yyyy"
//            time.text = dateFormatter.string(from: date1)
//        }
//        //Date().description(with: .current)
//        //if components.day
//    }
    
    func updateTime(time1: Date) {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone.current
        let date1 = time1
        let date2 = Date()
        dateFormatter.dateFormat = "yyyy"
        let year11 = dateFormatter.string(from: date1)
        let year22 = dateFormatter.string(from: date2)
        let start = Calendar.current.startOfDay(for: date1)
        let end = Calendar.current.startOfDay(for: date2)
        let date11 = Calendar.current.date(byAdding: .day, value: 6, to: date1)!
        let date22 = Calendar.current.date(byAdding: .day, value: 6, to: date2)!
        let nextWeekend1 = Calendar.current.nextWeekend(startingAfter: date11)
        let nextWeekend2 = Calendar.current.nextWeekend(startingAfter: date22)
        let components = Calendar.current.dateComponents([.day], from: start, to: end)
        if components.day == 0 {
            dateFormatter.dateFormat = "HH:mm"
            time.text = dateFormatter.string(from: date1)
        } else if components.day == 1 {
            time.text = "yesterday"
        } else if nextWeekend1 == nextWeekend2 {
            dateFormatter.dateFormat = "E"
            time.text = dateFormatter.string(from: date1)
        } else if year11 == year22 {
            dateFormatter.dateFormat = "MMM d"
            time.text = dateFormatter.string(from: date1)
        } else {
            dateFormatter.dateFormat = "MMM yyyy"
            time.text = dateFormatter.string(from: date1)
        }
        //Date().description(with: .current)
        //if components.day
    }
    
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
}
