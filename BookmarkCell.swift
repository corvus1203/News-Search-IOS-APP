import UIKit
import Alamofire

protocol BookmarkCellDelegate {
    func removeBookmark(news: News)
}

class BookmarkCell: UICollectionViewCell {
    
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var sectionLabel: UILabel!
    @IBOutlet weak var bookmarkBtn: UIButton!
    
    var delegate: BookmarkCellDelegate?
    
    var news: News!
    
    func setNews(news: News){
        self.news = news
        
        newsImageView.image = news.image
        titleLabel.text = news.title
        dateLabel.text = news.timeForBookmark
        sectionLabel.text = news.section
        
        self.contentView.layer.borderWidth = 1
        self.contentView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        self.contentView.layer.cornerRadius = 10
    }
    
    
    @IBAction func onCancelBookmark(_ sender: UIButton) {
        news.isBookmark = false
        self.superview!.superview!.makeToast("Article Removed from Bookmarks")
        self.delegate?.removeBookmark(news: news)
    }
    
}
