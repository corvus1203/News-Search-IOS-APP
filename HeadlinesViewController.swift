import UIKit
import XLPagerTabStrip
import Alamofire
import SwiftyJSON

class HeadlinesViewController: ButtonBarPagerTabStripViewController {
    
    let searchController = UISearchController(searchResultsController: AutoSuggestTableViewController())
    var tabbar: RootViewController!
    
    var keyword: String!
    var timer: Timer?

    override func viewDidLoad() {
        self.loadDesign()
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        searchController.delegate = self
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.searchBar.placeholder = "Enter keyword.."
        (searchController.searchResultsController as! AutoSuggestTableViewController).delegate = self
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
    }

    override func viewControllers(for pagerTabStripController: PagerTabStripViewController) -> [UIViewController] {
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let world = storyboard.instantiateViewController(identifier: "headlines") as! HeadlinesTableViewController
        world.section = "world"
        let business = storyboard.instantiateViewController(identifier: "headlines") as! HeadlinesTableViewController
        business.section = "business"
        let politics = storyboard.instantiateViewController(identifier: "headlines") as! HeadlinesTableViewController
        politics.section = "politics"
        let sports = storyboard.instantiateViewController(identifier: "headlines") as! HeadlinesTableViewController
        sports.section = "sports"
        let technology = storyboard.instantiateViewController(identifier: "headlines") as! HeadlinesTableViewController
        technology.section = "technology"
        let science = storyboard.instantiateViewController(identifier: "headlines") as! HeadlinesTableViewController
        science.section = "science"
        return [world, business, politics, sports, technology, science]
    }
    
    func loadDesign() {
        self.settings.style.selectedBarBackgroundColor = .systemBlue
        self.settings.style.selectedBarHeight = 3
        self.settings.style.buttonBarHeight = 50
        self.settings.style.buttonBarBackgroundColor = .white
        self.settings.style.buttonBarItemBackgroundColor = .white
        self.settings.style.buttonBarItemTitleColor = .systemGray
        self.settings.style.buttonBarItemLeftRightMargin = 2
        self.changeCurrentIndexProgressive = { (oldCell: ButtonBarViewCell?, newCell: ButtonBarViewCell?, progressPercentage: CGFloat, changeCurrentIndex: Bool, animated: Bool) -> Void in
            oldCell?.label.textColor = .systemGray
            newCell?.label.textColor = .systemBlue
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
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if (segue.destination is SearchTableViewController) {
            let vc = segue.destination as! SearchTableViewController
            vc.keyword = self.keyword
        }
    }
}

extension HeadlinesViewController: UISearchControllerDelegate, UISearchResultsUpdating, UISearchBarDelegate {
    
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

extension HeadlinesViewController: AutoSuggestTableViewDelegate {
    func searchNews(keyword: String) {
        self.keyword = keyword
        self.searchController.searchBar.endEditing(true)
        self.performSegue(withIdentifier: "showResults", sender: self)
    }
}
