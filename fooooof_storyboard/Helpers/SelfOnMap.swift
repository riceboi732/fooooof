import Foundation
import MapKit

class SelfOnMap: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var title: String?
    var imageUrl: String?
    
    func getImageUrl() -> String {
        return imageUrl ?? ""
    }
}
