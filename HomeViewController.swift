import UIKit
import CoreLocation
import Alamofire
import SwiftyJSON
import SwiftSpinner

class HomeViewController: UIViewController {
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var weatherImageView: UIImageView!
    @IBOutlet weak var cityLabel: UILabel!
    @IBOutlet weak var stateLabel: UILabel!
    @IBOutlet weak var tempLabel: UILabel!
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var newsTableView: UITableView!
    @IBOutlet weak var newsTableHeight: NSLayoutConstraint!
    @IBOutlet weak var weatherView: UIView!
    
    private let refreshControl = UIRefreshControl()
    private let locManager:CLLocationManager = CLLocationManager()
    private let geocoder = CLGeocoder()
    private let host = "http://localhost:8081/"
    
    let searchController = UISearchController(searchResultsController: AutoSuggestTableViewController())
        
    var tabbar: RootViewController!
    
    var news: [News] = []
    var selectedNews: News?
    var stateChange: [Int] = []
    var keyword: String!
    var timer: Timer?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        SwiftSpinner.show("Loading Home Page..")
        setup()
        locManager.requestWhenInUseAuthorization()
        locManager.requestLocation()
        getNews()
        setRadius()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setBookmarks()
        newsTableView.reloadData()
    }
    
    private func setup() {
        extendedLayoutIncludesOpaqueBars = true;
        tabbar = tabBarController as? RootViewController
        locManager.delegate = self
        newsTableView.dataSource = self
        newsTableView.delegate = self
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Enter keyword.."
        (searchController.searchResultsController as! AutoSuggestTableViewController).delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = true
        // ???
        definesPresentationContext = true
        
        scrollView.addSubview(refreshControl)
        refreshControl.addTarget(self, action: #selector(refreshNews(_:)), for: .valueChanged)
    }
    
    @objc private func refreshNews(_ sender: Any) {
        // Fetch Weather Data
        getNews()
    }
    
    private func setRadius() {
        weatherView.layer.cornerRadius = 10
        weatherView.layer.masksToBounds = true
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
    
    private func getSuggestions(keyword: String) {
        if (keyword == "") {
            return
        }
        let headers: HTTPHeaders = [
          "Ocp-Apim-Subscription-Key": "",
        ]
        let url = "https://api.bing.microsoft.com/v7.0/suggestions?q=" + keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        Alamofire.request(url, headers: headers).responseJSON( completionHandler: { autoSgstRes in
            switch autoSgstRes.result {
            case .success:
                if (autoSgstRes.result.value) != nil {
                    let json = JSON(autoSgstRes.result.value!)
                    var suggestions: [String] = []
                    for (_, suggestStr) in json["suggestionGroups"][0]["searchSuggestions"] {
                        suggestions.append(suggestStr["displayText"].string!)
                    }
                    if let resultsController = self.searchController.searchResultsController as? AutoSuggestTableViewController {
                        resultsController.suggestions = suggestions
                        resultsController.tableView.reloadData()
                    }
                }
            case .failure(let error):
                print("Failed to get Suggestions, error: \(error)")
            }
        })
    }
    
    private func getNews() {
        var tempNews:[News] = []
        let url = host + "guardian/?section=home"
        Alamofire.request(url).responseJSON(completionHandler: {newsRes in
            switch newsRes.result{
            case .success:
                if (newsRes.result.value) != nil {
                    let json = JSON(newsRes.result.value!)
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
                                self.newsTableView.reloadData()
                                self.newsTableView.rowHeight = 145
                                self.newsTableHeight.constant = CGFloat(json.count * 145)
                                self.newsTableView.reloadData()
                                SwiftSpinner.hide()
                                self.refreshControl.endRefreshing()
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
                            self.newsTableView.reloadData()
                            self.newsTableView.rowHeight = 145
                            self.newsTableHeight.constant = CGFloat(json.count * 145)
                            self.newsTableView.reloadData()
                            SwiftSpinner.hide()
                            self.refreshControl.endRefreshing()
//                            self.activityIndicatorView.stopAnimating()
                            }
                    }
                }
            }
            case .failure(let error):
                print("Failed to get News, error: \(error)")
            }
        })
    }
    
    func getWeather(city: String) {
        let url = "https://api.openweathermap.org/data/2.5/weather?q=" +
            city.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)! +
            "&units=metric&appid="
        Alamofire.request(url).responseJSON(completionHandler: {(response) in
            switch response.result{
            case .success:
                if((response.result.value) != nil) {
                    
                    let json = JSON(response.result.value!)
                    let temp = json["main"]["temp"]
                    let summary = json["weather"][0]["main"]
                    
                    switch summary {
                    case "Clouds":
                        self.weatherImageView.image = #imageLiteral(resourceName: "cloudy_weather")
                    case "Clear":
                        self.weatherImageView.image = #imageLiteral(resourceName: "clear_weather")
                    case "Snow":
                        self.weatherImageView.image = #imageLiteral(resourceName: "snowy_weather")
                    case "Rain":
                        self.weatherImageView.image = #imageLiteral(resourceName: "rainy_weather")
                    case "Thunderstorm":
                        self.weatherImageView.image = #imageLiteral(resourceName: "thunder_weather")
                    default:
                        self.weatherImageView.image = #imageLiteral(resourceName: "sunny_weather")
                    }
                    self.summaryLabel.text = summary.stringValue
                    self.tempLabel.text = String(Int(temp.doubleValue.rounded())) + "\u{B0}C"
                }
            case .failure(let error):
                print("Failed to get weather, error: \(error)")
            }
            
        })
    }
    
}

extension HomeViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            geocoder.reverseGeocodeLocation(location, completionHandler: {(placemarks, error) in
                if error != nil {
                    print("Failed to convert location: \(String(describing: error?.localizedDescription))")
                    return
                }
                guard let placemark = placemarks?.first else {
                    return
                }
                
                self.stateLabel.text = placemark.administrativeArea ?? ""
                
                let city = placemark.locality ?? ""
                self.cityLabel.text = city
                
                if city != "" {
                    self.getWeather(city: city)
                }
            });
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is DetailViewController) {
            let vc = segue.destination as! DetailViewController
            vc.news = self.selectedNews
        } else if (segue.destination is SearchTableViewController) {
            let vc = segue.destination as! SearchTableViewController
            vc.keyword = self.keyword
        }
    }
}

extension HomeViewController: UITableViewDataSource, UITableViewDelegate {
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.news.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let news = self.news[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: "NewsCell") as! NewsCell
        cell.setNews(news: news)
        return cell
    }
    
    func tableView(_ tableView: UITableView, contextMenuConfigurationForRowAt indexPath: IndexPath, point: CGPoint) -> UIContextMenuConfiguration? {
        let cell = tableView.cellForRow(at: indexPath) as! NewsCell
        let image = cell.bookmarkBtn.currentImage!
        let actionProvider: UIContextMenuActionProvider = { _ in
            let editMenu = UIMenu(title: "Menu", children: [
                UIAction(title: "Share with Twitter", image: #imageLiteral(resourceName: "twitter")) { _ in
                    let news = self.news[indexPath.row]
                    let url = URL(string: "https://twitter.com/intent/tweet?url=" + news.sharelink +  "&text=Check%20out%20this%20Article!&hashtags=CSCI_571_NewsApp")!
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                },
                UIAction(title: "Bookmark", image: image) { _ in
                    cell.onClickBookmark(cell.bookmarkBtn)
                }
            ])
            return editMenu
        }

        return UIContextMenuConfiguration(identifier: "unique-ID" as NSCopying, previewProvider: nil, actionProvider: actionProvider)

    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedNews = self.news[indexPath.row]
        self.performSegue(withIdentifier: "showDetail", sender: self)
    }
}

extension HomeViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        (searchController.searchResultsController as! AutoSuggestTableViewController).tableView.alpha = 0
        let keyword = searchController.searchBar.text!
        searchNews(keyword: keyword)
    }
    
    func updateSearchResults(for searchController: UISearchController) {
        let keyword = searchController.searchBar.text!
        renewInterval(keyword: keyword)
    }
    
    func renewInterval(keyword: String) {
        // Invalidate existing timer if there is one
        timer?.invalidate()
        // Begin a new timer from now
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: false, block: { timer in
            guard timer.isValid else {
                return
            }
            self.getSuggestions(keyword: keyword)
            (self.searchController.searchResultsController as! AutoSuggestTableViewController).tableView.alpha = 1
        })
    }
}

extension HomeViewController: AutoSuggestTableViewDelegate {
    func searchNews(keyword: String) {
        self.keyword = keyword
        self.searchController.searchBar.endEditing(true)
        self.performSegue(withIdentifier: "showResults", sender: self)
    }
}
