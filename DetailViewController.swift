import UIKit
import Alamofire
import SwiftyJSON
import SwiftSpinner
import Toast_Swift

protocol DetailDelegate {
    func addBookmark(news: News)
    func removeBookmark(news: News)
    func updateBookmark(news: News)
}

class DetailViewController: UIViewController {

    @IBOutlet weak var newsImage: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var descriptionLabel: UILabel!
    @IBOutlet weak var linkBtn: UIButton!
    
    let host:String = "http://localhost:8081/details/guardian?id="
    
    var news: News!
    var link: URL!
    var isBookmark: Bool!
    
    var bookmarkBtn: UIBarButtonItem!
    var twitterBtn: UIBarButtonItem!
    
    let defaults = UserDefaults.standard
    var delegate: DetailDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // this is called earlier than viewWillDisappear of HomeViewController
        delegate = tabBarController as? DetailDelegate
        isBookmark = news.isBookmark
        twitterBtn = UIBarButtonItem(image: (#imageLiteral(resourceName: "twitter")), style: .plain, target: self, action: #selector(onClickTwitterBtn))
        bookmarkBtn = UIBarButtonItem(image: (isBookmark ? UIImage(systemName: "bookmark.fill") : UIImage(systemName: "bookmark")), style: .plain, target: self, action: #selector(onClickBookmarkBtn))
        navigationItem.rightBarButtonItems = [twitterBtn, bookmarkBtn]
        getDetail()
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        delegate?.updateBookmark(news: news)
        isBookmark = news.isBookmark
        self.bookmarkBtn.image = isBookmark ? UIImage(systemName: "bookmark.fill"): UIImage(systemName: "bookmark")
    }
    
    @objc func onClickTwitterBtn() {
        let url = URL(string: "https://twitter.com/intent/tweet?url=" + news.sharelink +  "&text=check%20out%20this%20article!&hashtags=CSCI_571_NewsApp")!
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    @objc func onClickBookmarkBtn() {
        self.isBookmark = !(self.isBookmark)
        if self.isBookmark {
            delegate?.addBookmark(news: news)
            self.bookmarkBtn.image = UIImage(systemName: "bookmark.fill")
            self.view.makeToast("Article Bookmarked. Check out the Bookmarks tab to view")
        } else {
            delegate?.removeBookmark(news: news)
            self.bookmarkBtn.image = UIImage(systemName: "bookmark")
            self.view.makeToast("Article Removed from Bookmarks.")
        }
    }
    
    private func getDetail() {
        SwiftSpinner.show("Loading Detailed Article..")
        let url = URL(string: host + self.news.id)!
        Alamofire.request(url).responseJSON(completionHandler: { response in
            switch response.result {
            case .success:
                if response.result.value != nil {
                    let json = JSON(response.result.value!)
                    
                    let imageUrl = json["image"].string ?? ""
                    
                    if (imageUrl == self.news.imageUrl) {
                        self.newsImage.image = self.news.image
                        SwiftSpinner.hide()
                    } else if (imageUrl != "") {
                            let imageurl = URL(string: imageUrl)!
                            let data = try? Data(contentsOf: imageurl)
                            self.newsImage.image = UIImage(data: data!)
                    } else {
                        self.newsImage.image = #imageLiteral(resourceName: "default-guardian")
                        SwiftSpinner.hide()
                    }
                    
                    self.titleLabel.text = json["title"].string!
                    self.navigationItem.title = self.titleLabel.text
                    self.sectionLabel.text = json["section"].string!
                    
                    
                    let modifiedFont = String(format:"<span style=\"font-family: '-apple-system', 'HelveticaNeue'; font-size: 17;\">%@</span>", json["description"].string!)
                    let attrStr = try! NSMutableAttributedString(
                    data: modifiedFont.data(using: .unicode, allowLossyConversion: true)!,
                    options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding:String.Encoding.utf8.rawValue],
                    documentAttributes: nil)
                    let textRange = NSRange(location: 0, length: attrStr.length)
                    let paragraphStyle = NSMutableParagraphStyle()
                    paragraphStyle.lineBreakMode = .byTruncatingTail
                    attrStr.addAttribute(.paragraphStyle, value: paragraphStyle, range: textRange)
                    self.descriptionLabel.attributedText = attrStr

                    let formatter = DateFormatter()
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
                    let date = formatter.date(from: json["date"].string!)
                    formatter.dateFormat = "dd MMM yyyy"
                    self.dateLabel.text = formatter.string(from: date!)
                    
                    self.link = URL(string: json["sharelink"].string!)
                }
            case .failure(let error):
                print("Failed to get Detail, error: \(error)")
            }
        })
    }
    
    @IBAction func onClickLinkBtn(_ sender: Any) {
        UIApplication.shared.open(self.link!, options: [:], completionHandler: nil)
    }
    

}

extension NSAttributedString {
    internal convenience init?(html: String) {
        guard let data = html.data(using: String.Encoding.utf16, allowLossyConversion: false) else {
            // not sure which is more reliable: String.Encoding.utf16 or String.Encoding.unicode
            return nil
        }
        guard let attributedString = try? NSMutableAttributedString(data: data, options: [NSAttributedString.DocumentReadingOptionKey.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) else {
            return nil
        }
        self.init(attributedString: attributedString)
    }
}
