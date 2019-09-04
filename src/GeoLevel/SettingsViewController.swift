//
//  SettingsViewController.swift
//  GeoLevel
//
//  Created by Aliaksei Smuhaliou on 9/2/19.
//  Copyright © 2019 Aliaksei_Smuhaliou. All rights reserved.
//

import UIKit
import GEOSwift

class GeoJSONDecoder {
    
    static func readFeatures(at url: URL) -> [Feature] {
        let decoder = JSONDecoder()
        guard let data = try? Data(contentsOf: url),
            let geoJSON = try? decoder.decode(GeoJSON.self, from: data),
            case let .featureCollection(collection) = geoJSON else
        {
            return []
        }
        return collection.features
    }
}


extension URL {
    var fileName: String {
        return lastPathComponent.split(separator: ".").dropLast().joined(separator: ".")
    }
}

protocol SettingsViewControllerDelegate: AnyObject {
    func settings(_ vc: SettingsViewController, didSelectFeatures features: [Feature], title: String)
}

class SettingsViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    weak var delegate: SettingsViewControllerDelegate?
    
    var files: [[URL]] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()

        buildDataSource()
        
        NotificationCenter.default.addObserver(forName: .AppDidReceiveGeoJSONFile, object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self else { return }
            
            self.files = []
            self.buildDataSource()
            self.tableView.reloadData()
        }
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "UITableViewCell")
    }
    
    private func buildDataSource() {
        if let geoJSONURL = Bundle.main.url(forResource: "example", withExtension: "geojson") {
            // first section
            files.append([geoJSONURL])
        } else {
            print("Failed to find bundled example.geojson")
            files.append([])
        }
        
        if let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first,
            let dirContents = try? FileManager.default.contentsOfDirectory(at: documentsURL, includingPropertiesForKeys: nil, options: []) {
            // second section
            let importedGeojsonFiles = dirContents.filter{ $0.pathExtension == "geojson" }
            files.append(importedGeojsonFiles)
        } else {
            print("No imported files or unable to read FS")
            files.append([])
        }
    }
    
    private func readFeatures(at url: URL) -> [Feature] {
        return GeoJSONDecoder.readFeatures(at: url)
    }
}

extension SettingsViewController: UITableViewDelegate, UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return files.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return ["Bundle", "Imported"][section]
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return files[section].count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = files[indexPath.section][indexPath.row].fileName

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let url = files[indexPath.section][indexPath.row]
        let features = readFeatures(at: url)
        if !features.isEmpty {
            
            delegate?.settings(self, didSelectFeatures: features, title: url.fileName)
        } else {
            let alert = UIAlertController(title: "Error", message: "Failed to read features at \(url.lastPathComponent). Or the file is empty", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            present(alert, animated: true, completion: nil)
        }
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // first section is bundle
        return indexPath.section != 0
    }

    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        let url = files[indexPath.section].remove(at: indexPath.row)
        try? FileManager.default.removeItem(at: url)
        tableView.deleteRows(at: [indexPath], with: .fade)
    }
}
