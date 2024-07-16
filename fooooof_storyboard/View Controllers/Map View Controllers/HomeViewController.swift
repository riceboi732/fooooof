import UIKit
import MapKit
import CoreLocation
import FirebaseAuth
import Firebase
import FirebaseFirestore
import Foundation
import AudioToolbox
import FirebaseMessaging
import CoreGraphics
import Accelerate
import SDWebImage

class HomeViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, UNUserNotificationCenterDelegate  {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var searchViewButton: UIButton!
    @IBOutlet weak var eventViewButton: UIButton!
    @IBOutlet weak var messagesViewButton: UIButton!
    @IBOutlet weak var personalProfileButton: UIButton!
    @IBOutlet weak var miniViewContainer: UIView!
    @IBOutlet weak var peopleButton: UIButton!
    @IBOutlet weak var mapButton: UIButton!
    @IBAction func messagesViewButtonPressed(_ sender: Any) {
        //        print("view messages")
        let vc = storyboard?.instantiateViewController(withIdentifier: "Messages1ViewController") as! Messages1ViewController
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    @IBAction func personalProfileButtonPressed(_ sender: Any){
        let controller = storyboard?.instantiateViewController(identifier: "personalProfileViewController") as! PersonalProfileViewController
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    @IBAction func eventViewButtonPressed(_ sender: Any){
        let controller = storyboard?.instantiateViewController(identifier: "eventPageViewController") as! EventPageViewController
        controller.modalPresentationStyle = .fullScreen
        present(controller, animated: true, completion: nil)
    }
    
    @IBAction func peopleButtonPressed(_ sender: Any) {
        transitionToPeople()
    }
    
    let locationManager = CLLocationManager()
    var centerUser: Bool = true
    @Published var lastSeenLocation: CLLocation?
    var timer = Timer()
    let userId = Auth.auth().currentUser!.uid
    private let db = Firestore.firestore()
    
    var selectedFirstName: String?
    var selectedLastName: String?
    var selectedUsername: String?
    var selectedUid: String?
    var selectedMajor: String?
    var selectedCollege: String?
    var selectedClassYear: String?
    var selectedCompany: String?
    var selectedPositionAtCompany: String?
    var currentUserLocation: GeoPoint?
    var listener : ListenerRegistration? = nil
    var firstTime = true
    var buzzIndicator = 1
    var trayOriginal: CGFloat!
    var trayRightOffset: CGFloat!
    var trayRight: CGFloat!
    var trayLeft: CGFloat!
    var nearbyUid = [String]()
    var mainloaded = "false"
    
    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.showsCompass = false
        scheduledTimerWithTimeInterval()
        view.isUserInteractionEnabled = true
        miniViewContainer.isUserInteractionEnabled = true
        miniViewContainer.isHidden = true;
        snapShotListenerForBuzz()
        onAppIndication(userId)
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.didEnterBackgroundNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willTerminateNotification, object: nil)
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: UIApplication.willResignActiveNotification, object: nil)
        registerForRemoteNotification()
        DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            strongSelf.addToken()
        }
        mapButton.setTitle("", for: .normal)
        messagesViewButton.setTitle("", for: .normal)
        personalProfileButton.setTitle("", for: .normal)
        
        peopleButton.setTitle("", for: .normal)
        peopleButton.layer.shadowRadius = 1
        peopleButton.layer.shadowOpacity = 0.2
        peopleButton.layer.shadowOffset = CGSize(width: 0.1, height: 0.1)
        peopleButton.layer.shadowColor = UIColor.black.cgColor
        
        searchViewButton.setTitle("", for: .normal)
        searchViewButton.layer.shadowRadius = 1
        searchViewButton.layer.shadowOpacity = 0.2
        searchViewButton.layer.shadowOffset = CGSize(width: 0.1, height: 0.1)
        searchViewButton.layer.shadowColor = UIColor.black.cgColor
        
        addGesture()
        trayRightOffset = 400
        trayOriginal = miniViewContainer.frame.origin.x
        trayRight = miniViewContainer.frame.origin.x + trayRightOffset
        trayLeft = miniViewContainer.frame.origin.x - trayRightOffset
        
        UserDefaults.standard.set(userId, forKey: "selfUid")
        
        checkNameDefaults()
    }
    
    private func checkNameDefaults() {
        if UserDefaults.standard.object(forKey: "firstname") == nil {
            let userUid = Auth.auth().currentUser!.uid
            print("Big error in \(userUid)")
            Firestore.firestore().collection("users").document(userUid).getDocument { (snapshot, error) in
                if let dictionary = snapshot?.data() as? [String: AnyObject]{
                    UserDefaults.standard.set(dictionary["firstName"] as! String, forKey:"firstname")
                    UserDefaults.standard.set(dictionary["lastName"] as! String, forKey:"lastname")
                }
            }
        }
    }
    
    @objc func appMovedToBackground() {
        offAppIndication(userId)
    }
    
    @objc func appMovedToForeground() {
        onAppIndication(userId)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ToMiniProfile" {
            let controller = segue.destination as! MiniProfileViewController
            controller.selectedFirstName = selectedFirstName ?? ""
            controller.selectedLastName = selectedLastName ?? ""
            controller.selectedUid = selectedUid ?? ""
            controller.selectedMajor = selectedMajor ?? ""
            controller.selectedCollege = selectedCollege ?? ""
            controller.selectedClassYear = selectedClassYear ?? ""
            controller.selectedCompany = selectedCompany ?? ""
            controller.selectedPositionAtCompany = selectedPositionAtCompany ?? ""
            controller.view.isUserInteractionEnabled = true
            controller.profileImage.isUserInteractionEnabled = true
        }
    }
    
    func scheduledTimerWithTimeInterval(){
        getOthersLocation();
        timer = Timer.scheduledTimer(timeInterval: 300, target: self, selector: #selector(getOthersLocation), userInfo: nil, repeats: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.delegate = self
        locationManager.distanceFilter = 10
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        mapView.showsUserLocation = true
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first{
            if centerUser {
                render(location)
                centerUser = false
            }
            lastSeenLocation = location
            updateFirebaseLocation()
        }
    }
    
    @IBAction func locationButtonClicked(_ sender: Any) {
        if lastSeenLocation != nil {
            render(lastSeenLocation!)
        }
    }
    
    func render(_ location: CLLocation)
    {
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        let region = MKCoordinateRegion(center: coordinate, span: span)
        
        mapView.setRegion(region, animated: false)
        
        mapView.pointOfInterestFilter = .some(MKPointOfInterestFilter(including: []))
        
        mapView.delegate = self
    }
    
    func updateFirebaseLocation() {
        let user = Auth.auth().currentUser
        if let user = user {
            let currentUserID = user.uid
            let db = Firestore.firestore()
            
            if let lastSeenLocation = lastSeenLocation {
                let lat:Double = lastSeenLocation.coordinate.latitude
                let long:Double = lastSeenLocation.coordinate.longitude
                let geo = GeoPoint.init(latitude: lat, longitude: long)
                
                db.collection("users").whereField("uid", isEqualTo: currentUserID).getDocuments { (result, error) in
                    if error == nil{
                        for document in result!.documents{
                            db.collection("users").document(document.documentID).setData(["currentUserLocation" : geo], merge: true)
                        }
                    }
                }
            } else {
                print("Location not found")
            }
            
        }
    }
    
    @objc func getOthersLocation() {
        let db = Firestore.firestore()
        db.collection("users").getDocuments() { [weak self] (querySnapshot, err) in
            guard let strongSelf = self else {
                return
            }
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    strongSelf.addCoordToMap(document: document)
                    strongSelf.nearbyUid = [String]()
                    strongSelf.updateNearbyUidList(document: document)
                }
            }
        }
    }
    
    //call within getOthersLocation()
    //call within
    func updateNearbyUidList(document: QueryDocumentSnapshot) {
        print("updating nearby uid list and checking blocked lists.")
        if let coords = document.get("currentUserLocation") {
            let point = coords as! GeoPoint
            let latitude: CLLocationDegrees = point.latitude
            let longitude: CLLocationDegrees = point.longitude
            if let uid = document.get("uid") {
                if uid as! String != userId {
                    checkIfSecondaryFriend(uid: uid as! String) { [weak self] isSecondFriend in
                        guard let strongSelf = self else {
                            return
                        }
                        if (isSecondFriend) {
                            if let lastSeenLocation = strongSelf.lastSeenLocation {
                                let selfLocation: CLLocation = lastSeenLocation
                                let otherLocation: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
                                let distanceInMeters = selfLocation.distance(from: otherLocation)
                                if(distanceInMeters < 1609)
                                {
                                    strongSelf.nearbyUid.append(uid as! String)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    func nextFriend(friendUID: String, direction: String, completion: @escaping ([String]) -> Void) {
        nearbyUid.sort()
        if var index: Int = nearbyUid.firstIndex(of: friendUID) {
            //TODO: updating notifications accordingly
            if direction == "Next" {
                if index == nearbyUid.count-1 {
                    index = 0
                    updateProfile(uid: nearbyUid[index])
                } else {
                    index = index + 1
                    updateProfile(uid: nearbyUid[index])
                }
            } else {
                if index == 0 {
                    index = nearbyUid.count-1
                    updateProfile(uid: nearbyUid[index])
                } else {
                    index = index - 1
                    updateProfile(uid: nearbyUid[index])
                }
            }
        } else {
            print("Element is not present in the array.")
        }
        //index = index + 1, get next person info and update notifications
        //reselecting annotation
        let db = Firestore.firestore()
        //update arraylist to wait in background
        db.collection("users").getDocuments() { [weak self] (querySnapshot, err) in
            guard let strongSelf = self else {
                return
            }
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                strongSelf.nearbyUid = [String]()
                for document in querySnapshot!.documents {
                    strongSelf.updateNearbyUidList(document: document)
                }
                completion(strongSelf.nearbyUid)
            }
        }
    }
    
    
    func registerForRemoteNotification() {
        if #available(iOS 10.0, *) {
            let center  = UNUserNotificationCenter.current()
            
            center.requestAuthorization(options: [.sound, .alert, .badge]) { (granted, error) in
                if error == nil{
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                    }
                }
            }
            
        }
        else {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.sound, .alert, .badge], categories: nil))
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
            DispatchQueue.main.asyncAfter(deadline: .now()+1) { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.addToken()
            }
        }
    }
    
    func addToken() {
        Messaging.messaging().token { [weak self] token, error in
            guard let strongSelf = self else {
                return
            }
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
                fcmRegTokenMessage.text  = "fail"
            } else if let token = token {
                fcmRegTokenMessage.text  = "\(token)"
                strongSelf.db.collection("users").document(strongSelf.userId).setData(["token" : token],merge: true)
            }
        }
        
    }
    
    func addCoordToMap(document: QueryDocumentSnapshot) {
        if let coords = document.get("currentUserLocation") {
            if let uid = document.get("uid") {
                //only get first degree friends of first degree friends (fofs, aka second degree friends), not those of currently logged in user
                if uid as! String != userId {
                    let point = coords as! GeoPoint
                    let latitude: CLLocationDegrees = point.latitude
                    let longitude: CLLocationDegrees = point.longitude
                    checkIfSecondaryFriend(uid: uid as! String) { [weak self] isSecondFriend in
                        guard let strongSelf = self else {
                            return
                        }
                        self?.checkIfBlockedSecondDegreeFriend(blockerUid: self!.userId, blockedUid: uid as! String) { isBlocked in
                            if !isBlocked {
                                self?.checkIfBlockedSecondDegreeFriend(blockerUid: uid as! String, blockedUid: self!.userId) { isBlocked in
                                    if !isBlocked {
                                        if (isSecondFriend || uid as! String == strongSelf.userId) {
                                            strongSelf.addCustomPin(latitude: latitude, longitude: longitude, uid: uid as! String)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                else {
                    let point = coords as! GeoPoint
                    let latitude: CLLocationDegrees = point.latitude
                    let longitude: CLLocationDegrees = point.longitude
                    addSelfPin(latitude: latitude, longitude: longitude, uid: uid as! String)
                }
            }
        }
    }
    
    func checkIfSecondaryFriend(uid: String, completion: @escaping (Bool) -> Void) {
        checkIfBlockedSecondDegreeFriend(blockerUid: uid, blockedUid: userId) { isBlocked in
            if isBlocked {
                completion(false)
                print("this user is blocked and thus should not be second degree friend")
                return
            }
        }
        checkIfBlockedSecondDegreeFriend(blockerUid: userId, blockedUid: uid) { isBlocked in
            if isBlocked {
                completion(false)
                print("this user is blocked and thus should not be second degree friend")
                return
            }
        }
        
        let aDocRef =  db.collection("users").document(userId);
        aDocRef.getDocument { (document, error) in
            if let document = document, document.exists {
                let bInAFirstDocRef = aDocRef.collection("secondDegreeFriends").document(uid)
                bInAFirstDocRef.getDocument { (document1, error1) in
                    if let document1 = document1, document1.exists {
                        completion(true)
                        return
                    }
                }
            }
        }
        completion(false)
        return
    }
    
    func checkIfBlockedSecondDegreeFriend(blockerUid: String, blockedUid: String, completion: @escaping (Bool) -> Void) {
        let db = Firestore.firestore()
        db.collection("blocked").document(blockerUid).getDocument { (snapshot, error) in
            if snapshot?.exists ?? false {
                // EXIST
                if let dictionary = snapshot?.data() as? [String: AnyObject]{
                    let blocked = dictionary[blockedUid] as? Bool
                    if blocked == nil {
//                        print("This user is not blocked")
                        completion(false)
                    } else if blocked == true {
                        print("This user is blocked")
                        completion(true)
                        return
                    } else {
//                        print("This user was blocked but now isn't blocked")
                        completion(false)
                    }
                }
            } else {
                // NOT EXIST
                completion(false)
            }
        }
    }
    
    func addCustomPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, uid: String) {
        if let lastSeenLocation = lastSeenLocation {
            let selfLocation: CLLocation = lastSeenLocation
            let otherLocation: CLLocation = CLLocation(latitude: latitude, longitude: longitude)
            let distanceInMeters = selfLocation.distance(from: otherLocation)
            if(distanceInMeters < 1609)
            {
                let userOnMap = UserOnMap()
                userOnMap.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
                userOnMap.title = uid
                getImageUrl(uid:uid) { [weak self] url in
                    guard let strongSelf = self else {
                        return
                    }
                    //                    userOnMap.sd_setImage(with: url)
                    userOnMap.imageUrl = url
                    strongSelf.mapView.addAnnotation(userOnMap)
                }
            }
        }
    }
    
    func addSelfPin(latitude: CLLocationDegrees, longitude: CLLocationDegrees, uid: String) {
        if lastSeenLocation != nil {
            let selfOnMap = SelfOnMap()
            selfOnMap.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            selfOnMap.title = uid
            mapView.addAnnotation(selfOnMap)
            
            getImageUrl(uid:uid) { [weak self] url in
                guard let strongSelf = self else {
                    return
                }
                //                    userOnMap.sd_setImage(with: url)
                selfOnMap.imageUrl = url
                strongSelf.mapView.addAnnotation(selfOnMap)
            }
        }
    }
    
    func getImageUrl(uid: String, completion: @escaping (String) -> ()) {
        let db = Firestore.firestore()
        let docRef = db.collection("users").document(uid)
        var url = ""
        docRef.getDocument { (document, error) in
            if let document = document, document.exists {
                url = document.get("profileImageUrl") as! String
                completion(url)
            }
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if (annotation is MKUserLocation) {
            return nil
        } else if annotation.title == userId {
            let userOnMap = annotation as! SelfOnMap
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "userAnnotationView")
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: userOnMap, reuseIdentifier: "userAnnotationView")
            } else {
                annotationView!.annotation = annotation
            }
            let tap = tapGestrue(target: self, action: #selector(doubleTapped))
            tap.uid = (annotationView?.annotation?.title ?? "") ?? ""
            getName(uid: userId) { (name) in
                tap.myFirstName = name
            }
            getName(uid: tap.uid) { (name) in
                tap.selectedFirstName = name
            }
            tap.numberOfTapsRequired = 2
            annotationView?.canShowCallout = false
            annotationView?.isUserInteractionEnabled = true
            annotationView?.addGestureRecognizer(tap)
            return annotationView
            
        } else {
            let userOnMap = annotation as! UserOnMap
            var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: "userAnnotationView")
            
            if annotationView == nil {
                annotationView = MKAnnotationView(annotation: userOnMap, reuseIdentifier: "userAnnotationView")
                guard let url = URL(string: userOnMap.getImageUrl()) else { return MKAnnotationView()}
                
                DispatchQueue.global().async {
                    if let data = try? Data(contentsOf: url) {
                        if let originalImage = UIImage(data: data) {
                            DispatchQueue.main.async {
                                let image = Utilities.maskRoundedImage(image: originalImage, radius: min(originalImage.size.width, originalImage.size.height)/2)
                                var newSize: CGSize!
                                if min(image.size.width, image.size.height) <= 40 {
                                    newSize = CGSize(width: image.size.width, height: image.size.height)
                                    annotationView?.image = image
                                    annotationView?.frame.size = newSize
                                    annotationView?.canShowCallout = false
                                } else {
                                    let aspectRatio = image.size.width/image.size.height
                                    if aspectRatio > 1 {
                                        newSize = CGSize(width: 40, height: 40 / aspectRatio)
                                    } else {
                                        newSize = CGSize(width: 40 * aspectRatio, height: 40)
                                    }
                                    annotationView?.image = image
                                    annotationView?.frame.size = newSize
                                    annotationView?.canShowCallout = false
                                }
                            }
                        }
                    }
                }
            } else {
                annotationView!.annotation = annotation
            }
            let tap = tapGestrue(target: self, action: #selector(doubleTapped))
            tap.uid = (annotationView?.annotation?.title ?? "") ?? ""
            getName(uid: userId) { (name) in
                tap.myFirstName = name
            }
            getName(uid: tap.uid) { (name) in
                tap.selectedFirstName = name
            }
            tap.numberOfTapsRequired = 2
            annotationView?.isUserInteractionEnabled = true
            annotationView?.addGestureRecognizer(tap)
            return annotationView
        }
    }
    
    func addGesture() {
        view.isUserInteractionEnabled = true
        let gestureRecognizerNext = UISwipeGestureRecognizer(target: self, action: #selector(gestureNextFired(_:)))
        gestureRecognizerNext.direction = .left
        gestureRecognizerNext.numberOfTouchesRequired = 1
        view.addGestureRecognizer(gestureRecognizerNext)
        let gestureRecognizerPrev = UISwipeGestureRecognizer(target: self, action: #selector(gesturePrevFired(_:)))
        gestureRecognizerPrev.direction = .right
        gestureRecognizerPrev.numberOfTouchesRequired = 1
        view.addGestureRecognizer(gestureRecognizerPrev)
    }
    
    @objc func gestureNextFired(_ gesture: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.4, animations: { [weak self] () -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.miniViewContainer.frame.origin.x = strongSelf.trayLeft
        }, completion: { [weak self] (finished:Bool) in
            guard let strongSelf = self else {
                return
            }
            // the code you put here will be compiled once the animation finishes
            strongSelf.miniViewContainer.frame.origin.x = strongSelf.trayRight
            //TODO: with input selectedUid
            strongSelf.nextFriend(friendUID:strongSelf.selectedUid ?? "", direction: "Next") { nearbyUid in
                print("attempting to get next friend")
            }
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                strongSelf.miniViewContainer.frame.origin.x = strongSelf.trayOriginal
            })
        })
    }
    
    @objc func gesturePrevFired(_ gesture: UISwipeGestureRecognizer) {
        UIView.animate(withDuration: 0.5, animations: { [weak self] () -> Void in
            guard let strongSelf = self else {
                return
            }
            strongSelf.miniViewContainer.frame.origin.x = strongSelf.trayRight
        }, completion: { [weak self] (finished:Bool) in
            guard let strongSelf = self else {
                return
            }
            // the code you put here will be compiled once the animation finishes
            strongSelf.miniViewContainer.frame.origin.x = strongSelf.trayLeft
            //TODO: with input selectedUid
            strongSelf.nextFriend(friendUID:strongSelf.selectedUid ?? "", direction: "Prev") {nearbyUid in
                print("attempting to get prev friend")
            }
            UIView.animate(withDuration: 0.4, animations: { () -> Void in
                strongSelf.miniViewContainer.frame.origin.x = strongSelf.trayOriginal
            })
        })
    }
    
    func updateProfile(uid: String) {
        //        self.miniViewContainer.isHidden = false;
        //        let selectedAnnotation = view.annotation
        //        self.showSelectedLocation(coordinate: selectedAnnotation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
        //        let uid = selectedAnnotation?.title ?? ""
        showUserInfo(uid: uid ?? "") { [weak self] dataDict in
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
            let notificationName = Notification.Name(miniProfileNotificationKey)
            let notificationNameFull = Notification.Name(rawValue: fullProfileNotificationKey)
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo: dataDict)
            NotificationCenter.default.post(name: notificationNameFull, object: nil, userInfo: dataDict)
        }
    }
    
    @objc func doubleTapped(sender : tapGestrue) {
        if sender.uid != "" {
            checkChatRoomExistance(myUid: userId, friendUid: sender.uid, mymessage: "\(sender.myFirstName) tickled \(sender.selectedFirstName)") { [weak self] (userId, friendId, mymessage) in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.updateChat(myUid: userId, friendUid: friendId, mymessage: mymessage) { error in
                    let friendProfile = strongSelf.db.collection("users").document(friendId)
                    friendProfile.getDocument() {(snapshot, error) in
                        if snapshot?.get("buzz") != nil{
                            if snapshot?.get("buzz") as! Int == 1{
                                friendProfile.setData(["buzz" : 0], merge: true)
                            } else {
                                friendProfile.setData(["buzz" : 1], merge: true)
                            }
                        }
                    }
                }
            }
        }
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
        AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
    }
    
    //touch other places to close mini profile
    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
    {
        let touch = touches.first
        guard (touch?.location(in: view)) != nil else { return }
        _ = presentingViewController
        let pos = touch!.location(in: view)
        miniViewContainer.isHidden = true;
        //show bottom menu buttons
        mapButton.alpha = 1;
        messagesViewButton.alpha = 1;
        personalProfileButton.alpha = 1;
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        //after selecting mini profile, hide bottom menu
        mapButton.alpha = 0;
        messagesViewButton.alpha = 0;
        personalProfileButton.alpha = 0;
        //TODO: if we ever want to just disable self button from being pressed DON'T WORK
        if view.annotation is MKUserLocation {
            print("annotation is user location")
            mapView.deselectAnnotation(view.annotation, animated: false)
            print("deselected")
            mapButton.alpha = 1;
            messagesViewButton.alpha = 1;
            personalProfileButton.alpha = 1;
            return
        }
        //end
        
        miniViewContainer.isHidden = false;
        let selectedAnnotation = view.annotation
        showSelectedLocation(coordinate: selectedAnnotation?.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0))
        var uid = selectedAnnotation?.title ?? ""
        let location = selectedAnnotation?.coordinate
        if location == lastSeenLocation?.coordinate
        {
            uid = userId
        }
        showUserInfo(uid: uid ?? "") { [weak self] dataDict in
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
            let notificationName = Notification.Name(rawValue: miniProfileNotificationKey)
            let notificationNameFull = Notification.Name(rawValue: fullProfileNotificationKey)
            NotificationCenter.default.post(name: notificationName, object: nil, userInfo: dataDict)
            NotificationCenter.default.post(name: notificationNameFull, object: nil, userInfo: dataDict)
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
                strongSelf.currentUserLocation = document.get("currentUserLocation") as? GeoPoint
                let point = strongSelf.currentUserLocation!
                let lat = point.latitude
                let lon = point.longitude
                strongSelf.showSelectedLocation(coordinate: CLLocationCoordinate2D(latitude: lat, longitude: lon))
                
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
    
    func showSelectedLocation(coordinate: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.setRegion(region,animated: false)
    }
    
    func transitionToPeople() {
        let peopleViewController = storyboard?.instantiateViewController(withIdentifier: "PeopleNav") as? UINavigationController
        
        view.window?.rootViewController = peopleViewController
        view.window?.makeKeyAndVisible()
    }
    
    func transitionToMessages() {
        
        //        let vc = storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.navigationController) as! UINavigationController
        //        view.window?.rootViewController = vc
        //        view.window?.makeKeyAndVisible()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        if let launchOptions = launchOptions,
           let isLocationKey = launchOptions[UIApplication.LaunchOptionsKey.location] as? Bool,
           isLocationKey {
            locationManager.startMonitoringVisits()
            
        }
        return true
    }
    
    func snapShotListenerForBuzz() {
        listener = db.collection("users").document(userId).addSnapshotListener { [weak self] snapshot, error in
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
                    strongSelf.db.collection("users").document(strongSelf.userId).setData(["buzz" : 1], merge: true) { err in
                        strongSelf.firstTime = false
                    }
                } else if snapshot?.get("buzz") == nil {
                    strongSelf.buzzIndicator = 1
                    strongSelf.db.collection("users").document(strongSelf.userId).setData(["buzz" : 1], merge: true) { err in
                        strongSelf.firstTime = false
                    }
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
        db.collection("users").document(userId).setData(["onApp":1],merge: true) { [weak self] err in
            guard let strongSelf = self else {
                return
            }
            if Constants.Storyboard.notificationChatroomName != "" {
                let vc = strongSelf.storyboard?.instantiateViewController(withIdentifier: Constants.Storyboard.navigationController) as! UINavigationController
                strongSelf.view.window?.rootViewController = vc
                strongSelf.view.window?.makeKeyAndVisible()
            }
        }
    }
    
    func offAppIndication(_ userId: String) {
        db.collection("users").document(userId).setData(["onApp":0],merge: true)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        if listener != nil {
            listener?.remove()
        }
    }
}


class tapGestrue: UITapGestureRecognizer{
    var uid = ""
    var selectedFirstName = ""
    var myFirstName = ""
}



extension HomeViewController {
    
    
    func checkChatRoomExistance(myUid: String, friendUid: String, mymessage: String, completion: @escaping (_ myUid: String, _ friendUid: String, _ mymessage: String) -> Void)->Void {
        let chatroom = db.collection("users").document(myUid).collection("chats").document(friendUid)
        chatroom.getDocument{ [weak self] (snapshot,error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error{
                print("\(error)")
            } else if snapshot!.get("messageCount") == nil {
                strongSelf.db.collection("users").document(myUid).getDocument() {(snapshot1, error) in
                    let indexCount = snapshot1?.get("indexCount") as! Int
                    strongSelf.db.collection("users").document(myUid).setData(["indexCount": indexCount + 1], merge: true)
                    chatroom.setData(["chatroomIndex": indexCount + 1], merge: true) { err in
                        strongSelf.initiateChatroom(myUid, friendUid, chatroom) { (chatRoom) in
                            completion(myUid, friendUid, mymessage)
                        }
                        strongSelf.db.collection("users").document(myUid).getDocument() { (snapshot1, error) in
                            let chatRoomCount = snapshot1?.get("chatRoomCount") as! Int + 1
                            strongSelf.db.collection("users").document(myUid).setData(["chatRoomCount" : chatRoomCount], merge: true)
                        }
                    }
                }
            } else {
                completion(myUid, friendUid, mymessage)
            }
        }
    }
    
    
    
    func creatMessageDocument(_ chatroom2 : DocumentReference,_ myUid: String, _ friendUid : String, _ sender : String, _ count : Int, _ mymessage : String, completion : @escaping ()->()){
        chatroom2.collection("messages").document(myUid+friendUid+"!"+String(count+1)).setData(["sender":sender, "message":mymessage, "index":count+1],merge: true) { err in
            completion()
        }
    }
    
    func updateChat(myUid: String, friendUid: String, mymessage: String, completion: @escaping (_ error: Error?) -> Void)->Void{
        let chatroom = db.collection("users").document(myUid).collection("chats").document(friendUid)
        chatroom.getDocument{ [weak self] (snapshot,error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error{
                print("\(error)")
                completion(error)
            } else {
                let count1 = snapshot?.get("messageCount") as! Int
                strongSelf.creatMessageDocument(chatroom, myUid, friendUid, "me", count1, mymessage) { () in
                    chatroom.setData(["lastMessage": mymessage, "sender": "me", "time": Date()], merge: true) { err in
                        chatroom.setData(["messageCount":count1+1], merge: true)
                    }
                    chatroom.getDocument() { (snapshot, error) in
                        strongSelf.db.collection("users").document(myUid).getDocument() { (snapshot1, error) in
                            var index = snapshot1?.get("indexCount") as! Int
                            if snapshot?.get("chatroomIndex") as! Int != index {
                                index = index + 1
                                chatroom.setData(["chatroomIndex" : index], merge: true)
                                strongSelf.db.collection("users").document(myUid).setData(["indexCount" : index], merge: true)
                            }
                        }
                    }
                }
                
            }
        }
        
        let chatroom2 = db.collection("users").document(friendUid).collection("chats").document(myUid)
        chatroom2.getDocument{ [weak self] (snapshot1,error) in
            guard let strongSelf = self else {
                return
            }
            if let error = error{
                print("\(error)")
                completion(error)
            } else {
                var index1 = 0
                var count = 0
                if snapshot1!.get("messageCount") == nil {
                    chatroom2.setData(["chatroomIndex" : 0], merge: true)
                    strongSelf.initiateChatroom(friendUid, myUid, chatroom2) { (chatroom2) in
                    }
                    let chatPage = strongSelf.db.collection("users").document(friendUid)
                    chatPage.getDocument(){ (snapshot, error) in
                        if error != nil {
                            print("Error")
                        } else {
                            var count = snapshot?.get("chatRoomCount") as! Int
                            count = count + 1
                            strongSelf.db.collection("users").document(friendUid).setData(["chatRoomCount" : count],merge: true)
                        }
                    }
                } else {
                    count = snapshot1!.get("messageCount") as! Int
                    index1 = snapshot1?.get("chatroomIndex") as! Int
                }
                strongSelf.creatMessageDocument(chatroom2, friendUid, myUid, "friend", count, mymessage) { () in
                    chatroom.setData(["lastMessage": mymessage, "sender": "friend", "time": Date()], merge: true) { err in
                        chatroom.setData(["messageCount":count+1], merge: true)
                    }
                    strongSelf.db.collection("users").document(friendUid).getDocument() { (snapshot, error) in
                        var index = snapshot?.get("indexCount") as! Int
                        if index1 != index {
                            index = index + 1
                            chatroom2.setData(["chatroomIndex" : index], merge: true)
                            strongSelf.db.collection("users").document(friendUid).setData(["indexCount" : index], merge: true)
                        }
                    }
                }
            }
        }
        completion(nil)
    }
    
    func initiateChatroom(_ myUid : String, _ friendUid : String, _ chatroom : DocumentReference, completion : @escaping (_ chatroom : DocumentReference)->()){
        db.collection("users").document(friendUid).getDocument() { (snapshot, error) in
            let firstName = snapshot?.get("firstName")
            let lastName = snapshot?.get("lastName")
            chatroom.setData(["messageCount": 0, "myUid":myUid, "friendUid":friendUid, "firstName": firstName ?? "noFirstName", "lastName": lastName as Any], merge: true) { err in
                chatroom.collection("messages").document(myUid+friendUid+"!0").setData(["sender":"initialiser", "message":"initialiser"], merge: true) { err in
                    completion(chatroom)
                }
            }
        }
    }
    
}

extension CLLocationCoordinate2D: Equatable {}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

