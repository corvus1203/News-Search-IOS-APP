import Foundation
import UIKit
import SwiftyJSON
import Alamofire

class News: NSObject, NSCoding {
    
    var imageUrl: String!
    var image: UIImage!
    var title: String!
    var time: String!
    var timeForBookmark: String!
    var section: String!
    var isBookmark: Bool!
    var sharelink: String!
    var id:String!
    
    init(json:JSON, image:UIImage, isBookmark:Bool) {
        self.imageUrl = json["image"].string!
        self.image = image
        self.title = json["title"].string!
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let publishDate = formatter.date(from: json["date"].string!)
        var diff = -Int((publishDate?.timeIntervalSinceNow)!)
        if (diff < 60) {
            self.time = String("\(diff)s ago")
        } else if (diff < 3600) {
            diff /= 60
            self.time = String("\(diff)m ago")
        } else if (diff < 86400) {
            diff /= 3600
            self.time = String("\(diff)h ago")
        } else if (diff < 604800) {
            diff /= 86400
            self.time = String("\(diff)d ago")
        } else if (diff < 2592000) {
            diff /= 604800
            self.time = String("\(diff)w ago")
        } else if (diff < 31536000) {
            diff /= 2592000
            self.time = String("\(diff)mo ago")
        } else {
            diff /= 31536000
            self.time = String("\(diff)y ago")
        }
        formatter.dateFormat = "dd MMM"
        self.timeForBookmark = formatter.string(from: publishDate!)
        self.section = "| " + json["section"].string!
        self.isBookmark = isBookmark
        self.sharelink = json["sharelink"].string!
        self.id = json["id"].string!
    }
    
    func encode(with coder: NSCoder) {
        coder.encode(imageUrl, forKey: "imageUrl")
        coder.encode(image.jpegData(compressionQuality: 0), forKey: "image")
        coder.encode(title, forKey: "title")
        coder.encode(time, forKey: "time")
        coder.encode(section, forKey: "section")
        coder.encode(id, forKey: "id")
    }
    
    required init?(coder: NSCoder) {
        self.imageUrl = coder.decodeObject(forKey: "imageUrl") as? String
        // need to refetch the image
        self.image = UIImage(data: coder.decodeObject(forKey: "image") as! Data)
        self.title = coder.decodeObject(forKey: "title") as? String
        self.time = coder.decodeObject(forKey: "time") as? String
        self.section = coder.decodeObject(forKey: "section") as? String
        self.id = coder.decodeObject(forKey: "id") as? String
        self.isBookmark = true
    }
    
}
