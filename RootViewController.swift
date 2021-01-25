import UIKit

class RootViewController: UITabBarController {

    var bookmarks: [News] = []
    
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
//        defaults.removeObject(forKey: "bookmarks")
        getBookmarks()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        setBookmarks()
    }
    
    private func getBookmarks() {
        let data = defaults.object(forKey: "bookmarks") as? Data ?? nil
        if data != nil {
            guard let unarchivedBookmarks = try? NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data!)
                else {
                    print("Failed to unarchive data")
                    return
            }
         self.bookmarks = unarchivedBookmarks as! [News]
        }
    }
    
    private func setBookmarks() {
        do {
            let data = try NSKeyedArchiver.archivedData(withRootObject: self.bookmarks, requiringSecureCoding: false)
            defaults.set(data, forKey: "bookmarks")
        } catch {
            return
        }
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}

extension RootViewController: NewsCellDelegate, DetailDelegate {
    func addBookmark(news: News) {
        bookmarks.append(news)
        news.isBookmark = true
    }
    
    func removeBookmark(news: News) {
        bookmarks.removeAll(where: {$0.id == news.id})
        news.isBookmark = false
    }
    
    func updateBookmark(news: News) {
        news.isBookmark = false
        for bookmark in bookmarks {
            if (bookmark.id == news.id) {
                news.isBookmark = true
                break
            }
        }
    }
}
