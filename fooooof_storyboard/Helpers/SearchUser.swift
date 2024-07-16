import Foundation

class SearchUser: NSObject {
   
    var username: String?
    var firstName: String?
    var lastName: String?
    var uid: String?
    var profileUrl: String?
    
    func getName() -> String {
        return "\(firstName ?? "First") \(lastName ?? "Last")"
    }
    
    func getUsername() -> String {
        return "\(username ?? "username")"
    }
    
    func getUid() -> String {
        return "\(uid ?? "uid")"
    }
    
    func getProfilePic() -> String {
        return "\(profileUrl ?? "")"
    }
}
