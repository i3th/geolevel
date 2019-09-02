//
//  SettingsViewController.swift
//  GeoLevel
//
//  Created by Aliaksei Smuhaliou on 9/2/19.
//  Copyright © 2019 Aliaksei_Smuhaliou. All rights reserved.
//

import UIKit
import GEOSwift

protocol SettingsViewControllerDelegate: AnyObject {
    func settings(_ vc: SettingsViewController, didSelectFeatures features: [Feature])
}

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: SettingsViewControllerDelegate?

    let bundledFiles = ["1", "2"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    private func readFeatures(of fileName: String) -> [Feature] {
        let decoder = JSONDecoder()
        guard let geoJSONURL = Bundle.main.url(forResource: fileName, withExtension: "geojson"),
            let data = try? Data(contentsOf: geoJSONURL),
            let geoJSON = try? decoder.decode(GeoJSON.self, from: data),
            case let .featureCollection(collection) = geoJSON else
        {
            return []
        }
        return collection.features
    }

}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return bundledFiles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = bundledFiles[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let fileName = bundledFiles[indexPath.row]
        let features = readFeatures(of: fileName)
        if !features.isEmpty {
            delegate?.settings(self, didSelectFeatures: features)
        } else {
            let alert = UIAlertController(title: "Error", message: "Failed to read features at \(fileName). Or the file is empty", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            present(alert, animated: true, completion: nil)
        }
    }
}
