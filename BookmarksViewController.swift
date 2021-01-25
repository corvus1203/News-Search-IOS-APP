import UIKit


class BookmarksViewController: UIViewController {
    
    @IBOutlet weak var emptyBookmarkView: UIView!
    @IBOutlet weak var collectionView: UICollectionView!
    let defaults = UserDefaults.standard
    
    var tabbar: RootViewController!
    var selectedNews: News?

    override func viewDidLoad() {
        super.viewDidLoad()
        tabbar = tabBarController as? RootViewController
        collectionView.dataSource = self
        collectionView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getBookmarks()
    }

    private func getBookmarks() {
        if tabbar.bookmarks.isEmpty {
            emptyBookmarkView.alpha = 1
        } else {
            emptyBookmarkView.alpha = 0
        }
        self.collectionView.reloadData()
   }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using [segue destinationViewController].
        // Pass the selected object to the new view controller.
        if (segue.destination is DetailViewController) {
            let vc = segue.destination as! DetailViewController
            vc.news = self.selectedNews
        }
    }
    
}

extension BookmarksViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of items
        if tabbar.bookmarks.isEmpty {
            self.emptyBookmarkView.alpha = 1
        } else {
            self.emptyBookmarkView.alpha = 0
        }
        return tabbar.bookmarks.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let news = self.news[indexPath.row]
        let news = tabbar.bookmarks[indexPath.row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "BookmarkCell", for: indexPath) as! BookmarkCell
    
        // Configure the cell
        cell.setNews(news: news)
        cell.delegate = self
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, contextMenuConfigurationForItemAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let cell = collectionView.cellForItem(at: indexPath) as! BookmarkCell
        let image = cell.bookmarkBtn.currentImage!
        let actionProvider: UIContextMenuActionProvider = { _ in
            let editMenu = UIMenu(title: "Menu", children: [
                UIAction(title: "Share with Twitter", image: #imageLiteral(resourceName: "twitter")) { _ in
                    let news = self.tabbar.bookmarks[indexPath.row]
                let url = URL(string: "https://twitter.com/intent/tweet?url=" + news.sharelink +  "&text=check%20out%20this%20article!&hashtags=CSCI_571_NewsApp")!
                UIApplication.shared.open(url, options: [:], completionHandler: nil)},
                UIAction(title: "Bookmark", image: image) { _ in
                    cell.onCancelBookmark(cell.bookmarkBtn)
                }
            ])
            return editMenu
        }

        return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)

    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        self.selectedNews = tabbar.bookmarks[indexPath.row]
        self.performSegue(withIdentifier: "showDetail", sender: self)
    }

}

extension BookmarksViewController: BookmarkCellDelegate{
    func removeBookmark(news: News) {
        tabbar.bookmarks.removeAll(where: {$0.id == news.id})
        self.collectionView.reloadData()
    }
}
