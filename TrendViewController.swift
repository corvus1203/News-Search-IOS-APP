import UIKit
import Charts
import Alamofire
import SwiftyJSON

class TrendViewController: UIViewController {

    @IBOutlet weak var keywordTextField: UITextField!
    @IBOutlet weak var chartView: LineChartView!
    
    private let host = "http://localhost:8081/trend?keyword="
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        keywordTextField.delegate = self
        setChartValues()
    }
    
    func setChartValues(keyword: String = "Coronavirus") {
        let encodeKeyword = keyword.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let url = URL(string: self.host + encodeKeyword)!
        Alamofire.request(url).responseJSON(completionHandler: { response in
            switch response.result {
            case .success:
                if response.result.value != nil {
                    let json = JSON(response.result.value!).array!
                    if json.count > 0 {
                        let values = (0..<json.count).map{ i -> ChartDataEntry in
                            return ChartDataEntry(x: Double(i), y: json[i].double!)
                        }
                        let dataSet = LineChartDataSet(entries: values, label: "Trending Chart for " + keyword)
                        dataSet.setColor(.systemBlue)
                        dataSet.setCircleColor(.systemBlue)
                        dataSet.circleRadius = 5
                        dataSet.circleHoleRadius = 0
                        let data = LineChartData(dataSet: dataSet)
                        self.chartView.data = data
                    } else {
                        self.chartView.data = nil
                    }
                    
                }
            case .failure(let error):
                print("Failed to get trend, error: \(error)")
            }
        })
    }
    
}

extension TrendViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        let keyword = textField.text ?? ""
        if keyword != "" {
            self.setChartValues(keyword: keyword)
        }
        return false
    }
}
