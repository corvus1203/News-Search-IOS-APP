import UIKit
import Toast_Swift

protocol NewsCellDelegate {
    func addBookmark(news: News)
    func removeBookmark(news: News)
}

class NewsCell: UITableViewCell {

    @IBOutlet weak var offsetView: UIView!
    @IBOutlet weak var newsImageView: UIImageView!
    @IBOutlet weak var newsTitleLabel: UILabel!
    @IBOutlet weak var newsTimeLabel: UILabel!
    @IBOutlet weak var newsSectionLabel: UILabel!
    @IBOutlet weak var bookmarkBtn: UIButton!
    
    var news: News!
    
    var delegate: NewsCellDelegate?
    
    func setNews(news: News) {
        self.news = news
        delegate = UIApplication.shared.windows.first?.rootViewController as? RootViewController
        newsImageView.image = news.image
        newsTitleLabel.text = news.title
        newsTimeLabel.text = news.time
        newsSectionLabel.text = news.section
        let bookmarkImage = ((news.isBookmark ? UIImage(systemName: "bookmark.fill"): UIImage(systemName: "bookmark"))!)
        bookmarkBtn.setImage(bookmarkImage, for: .normal)
        
        offsetView.layer.cornerRadius = 10
        offsetView.layer.borderWidth = 1
        offsetView.layer.borderColor = #colorLiteral(red: 0.8039215803, green: 0.8039215803, blue: 0.8039215803, alpha: 1)
        newsImageView.layer.cornerRadius = 10
        
    }
    
    
    @IBAction func onClickBookmark(_ sender: UIButton) {
        news.isBookmark = !news.isBookmark
        let bookmarkImage = ((news.isBookmark ? UIImage(systemName: "bookmark.fill"): UIImage(systemName: "bookmark"))!)
        sender.setImage(bookmarkImage, for: .normal)
        if news.isBookmark {
            // makeToast on the safe area
            self.superview!.superview!.superview!.superview!.makeToast("Article Bookmarked. Check out the Bookmarks tab to view")
            delegate?.addBookmark(news: news)
        } else {
            self.superview!.superview!.superview!.superview!.makeToast("Article Removed from Bookmarks.")
            delegate?.removeBookmark(news: news)
        }
        
    }
}
