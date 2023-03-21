//
//  ViewController.swift
//  weatherApp
//
//  Created by Account on 2023-03-20.
//

import UIKit
import CoreLocation

class ViewController: UIViewController, UITextFieldDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var conditionsLabel: UILabel!
    
    @IBOutlet weak var searchTextField: UITextField!
    
    @IBOutlet weak var weatherImage: UIImageView!
    
    @IBOutlet weak var tempratureLabel: UILabel!
    
    @IBOutlet weak var locationName: UILabel!
    
    let locationManager = CLLocationManager()
    
    var cel: Float = 0.00
    var far: Float = 0.00
    var toggle = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        searchTextField.delegate = self
        displaySampleImageForDemo()
        // Do any additional setup after loading the view.
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        loadWeather(search: searchTextField.text)
        textField.endEditing(true)
        return true
    }
    
    func displaySampleImageForDemo() {
        let config = UIImage.SymbolConfiguration(paletteColors: [.systemRed, .systemTeal, .systemYellow])
        weatherImage.preferredSymbolConfiguration = config
        weatherImage.image = UIImage(systemName: "sun.min.fill")
    }
    
    @IBAction func currentLocation(_ sender: UIButton) {
        locationManager.stopUpdatingLocation()
        
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
        locationManager.startUpdatingLocation()
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let locationValue = manager.location?.coordinate else { return }
        loadWeather(search: "\(locationValue.latitude),\(locationValue.longitude)")
        
    }
    
    @IBAction func tempratureTypeBtn(_ sender: UIButton) {
        if toggle {
            tempratureLabel.text = "\(far)°F"
            toggle = false
        } else {
            tempratureLabel.text = "\(cel)°C"
            toggle = true
        }
    }
    
    @IBAction func searchLocation(_ sender: UIButton) {
        loadWeather(search: searchTextField.text)
    }
    
    func loadWeather(search: String?) {
        guard let search = search else {
            return
        }
        
        guard let url = getUrl(query: search) else {
            print("Could not get url")
            return
        }
        
        let urlSession = URLSession.shared
        
        let dataTask = urlSession.dataTask(with: url) { data, response, error in
            print("Network call complete")
            
            guard let data = data else {
                print("No data found")
                return
            }
            
            
            if let weatherResponse = self.parseJson(data: data) {
                print(weatherResponse.location.name)
                print(weatherResponse.current.temp_c)
                print(weatherResponse.current.condition)
                
                self.cel = weatherResponse.current.temp_c
                self.far = weatherResponse.current.temp_f
                
                self.setImageFromUrl("https:\(weatherResponse.current.condition.icon)", on: self.weatherImage)
                DispatchQueue.main.async {
                    
                    if weatherResponse.current.is_day == 1 {
                        self.view.layer.contents = UIImage(named: "day_1")?.cgImage
                        self.tempratureLabel.textColor = UIColor.black
                        self.locationName.textColor = UIColor.black
                        self.searchTextField.backgroundColor = UIColor.white

                    } else {
                        self.view.layer.contents = UIImage(named: "urban")?.cgImage
                        self.tempratureLabel.textColor = UIColor.yellow
                        self.locationName.textColor = UIColor.white
                        self.searchTextField.backgroundColor = UIColor.gray
                    }
                    
                    self.locationName.text = weatherResponse.location.name
                    self.tempratureLabel.text = "\(weatherResponse.current.temp_c)°C"
                    self.conditionsLabel.text = weatherResponse.current.condition.text
                    
                }
            }
        }
        
        dataTask.resume()
        
    }
    
    func setImageFromUrl(_ urlString: String, on imageView: UIImageView) {
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard let data = data, let image = UIImage(data: data) else { return }
            
            DispatchQueue.main.async {
                imageView.image = image
            }
        }
        
        task.resume()
    }
    
    private func getUrl(query: String) -> URL? {
        let baseUrl = "https://api.weatherapi.com"
        let endpoint = "/v1/current.json"
        let apiKey = "13c1c685a3a74754bab182229232003"
        guard let url = "\(baseUrl)\(endpoint)?key=\(apiKey)&q=\(query)"
            .addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return nil
        }
        
        print(url)
        
        return URL(string: url)
    }
        
    func parseJson(data: Data) -> WeatherResponse? {
        let decoder = JSONDecoder()
        var weather: WeatherResponse?
        do {
            weather = try decoder.decode(WeatherResponse.self, from: data)
        } catch {
            print("Error decoding: \(error)")
        }
        return weather
    }
    
}

struct WeatherResponse: Decodable {
    let location: Location
    let current: Weather
}

struct Location: Decodable {
    let name: String
}

struct Weather: Decodable {
    let temp_c: Float
    let temp_f: Float
    let is_day: Int
    let condition: Conditions
}

struct Conditions: Decodable {
    let code: Int
    let text: String
    let icon: String
}
