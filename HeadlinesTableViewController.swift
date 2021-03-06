import UIKit
import Alamofire
import SwiftyJSON
import SwiftSpinner
import XLPagerTabStrip

class HeadlinesTableViewController: UITableViewController {


    private let host = "http://localhost:8081/guardian/?section="
    
    var tabbar: RootViewController!
    var news: [News] = []
    var section: String!
    var selectedNews: News!
        
    override func viewDidLoad() {
        super.viewDidLoad()
        tabbar = UIApplication.shared.windows.first?.rootViewController as? RootViewController
        SwiftSpinner.show("Loading " + self.section.uppercased() + " Headlines..")
        refreshControl = UIRefreshControl()
        refreshControl!.addTarget(self, action: #selector(refreshNews(_:)), for: .valueChanged)
        getNews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setBookmarks()
        tableView.reloadData()
    }
    
    @objc private func refreshNews(_ sender: Any) {
        // Fetch Weather Data
        getNews()
    }
    
    func setBookmarks() {
        for news in self.news {
            news.isBookmark = false
            for bookmark in tabbar.bookmarks {
                if news.id == bookmark.id {
                    news.isBookmark = true
                }
            }
        }
    }
    
    func getNews() {
        var tempNews:[News] = []
        let str = self.host + self.section
        let url = URL(string: str)!
        Alamofire.request(url).responseJSON { (response) in
            switch response.result {
            case .success:
                if (response.result.value) != nil {
                    let json = JSON(response.result.value!)
                    for (i, newsData) in json {
                            if (newsData["image"].string! != "") {
                                let imageurl = URL(string: newsData["image"].string!)!
                                let data = try? Data(contentsOf: imageurl)
                                let image = UIImage(data: data!)!
                                let news = News(json: newsData, image: image, isBookmark: false)
                                if (Int(i)! < tempNews.count) {
                                    tempNews.insert(news, at: Int(i)!)
                                } else {
                                    tempNews.append(news)
                                }
                                if (tempNews.count == json.count) {
                                    self.news = tempNews
                                    self.setBookmarks()
                                    self.tableView.reloadData()
                                    self.tableView.rowHeight = 145
                                    SwiftSpinner.hide()
                                    self.refreshControl!.endRefreshing()
                                }
                        } else {
                            let image =  #imageLiteral(resourceName: "default-guardian")
                            let news = News(json: newsData, image: image, isBookmark: false)
                            if (Int(i)! < tempNews.count) {
                                tempNews.insert(news, at: Int(i)!)
                            } else {
                                tempNews.append(news)
                            }
                            
                            if (tempNews.count == json.count) {
                                self.news = tempNews
                                self.setBookmarks()
                                self.tableView.reloadData()
                                self.tableView.rowHeight = 145
                                SwiftSpinner.hide()
                                self.refreshControl!.endRefreshing() //???
                            }
                        }
                    }
                }
            case .failure(let error) :
                print("Failed to get Results, error: \(error)")
            }
        }
        
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return self.news.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let news = self.news[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell") as! NewsCell
        cell.setNews(news: news)
        return cell
    }
    
    override func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
         let cell = tableView.cellForRow(at: indexPath) as! NewsCell
         let image = cell.bookmarkBtn.currentImage!
         let actionProvider: UIContextMenuActionProvider = { _ in
             let editMenu = UIMenu(title: "Menu", children: [
                 UIAction(title: "Share with Twitter", image: #imageLiteral(resourceName: "twitter")) { _ in
                 let news = self.news[indexPath.row]
                 let url = URL(string: "https://twitter.com/intent/tweet?url=" + news.sharelink +  "&text=check%20out%20this%20article!&hashtags=CSCI_571_NewsApp")!
                 UIApplication.shared.open(url, options: [:], completionHandler: nil)},
                 UIAction(title: "Bookmark", image: image) { _ in
                     cell.onClickBookmark(cell.bookmarkBtn)
                 }
             ])
             return editMenu
         }

         return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)

     }
     
     override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         self.selectedNews = self.news[indexPath.row]
         self.performSegue(withIdentifier: "showDetail", sender: self)
     }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
        if (segue.destination is DetailViewController) {
            let vc = segue.destination as! DetailViewController
            vc.news = self.selectedNews
        }
    }
}

extension HeadlinesTableViewController: IndicatorInfoProvider {
    
    func indicatorInfo(for pagerTabStripController: PagerTabStripViewController) -> IndicatorInfo {
        return IndicatorInfo(title: self.section.uppercased())
    }
    
}
