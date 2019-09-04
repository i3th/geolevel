//
//  AppDelegate.swift
//  GeoLevel
//
//  Created by Aliaksei Smuhaliou on 8/31/19.
//  Copyright © 2019 Aliaksei_Smuhaliou. All rights reserved.
//

import UIKit

extension Notification.Name {
    static let AppDidReceiveGeoJSONFile = NSNotification.Name("AppDidReceiveGeoJSONFile")
}

struct AppDidReceiveGeoJSONFileParams {
    
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        return true
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        guard let destURL = documentsURL?.appendingPathComponent(url.lastPathComponent) else {
            return false
        }
        do {
            try FileManager.default.copyItem(at: url, to: destURL)
            NotificationCenter.default.post(name: .AppDidReceiveGeoJSONFile, object: nil, userInfo: ["url": destURL])
        } catch {
            let alert = UIAlertController(title: "Cannot save the file", message: error.localizedDescription, preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            app.keyWindow?.rootViewController?.present(alert, animated: true, completion: nil)
            return false
        }
        return true
    }
}

