import Foundation
import UIKit

class Weather {
    var image: UIImage
    var city: String
    var state: String
    var temp: String
    var summary: String
    
    init(image:UIImage, city:String, state:String, temp: String, summary:String) {
        self.image = image
        self.city = city
        self.state = state
        self.temp = temp
        self.summary = summary
    }
}
