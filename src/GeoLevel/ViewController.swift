//
//  ViewController.swift
//  GeoLevel
//
//  Created by Aliaksei Smuhaliou on 8/31/19.
//  Copyright © 2019 Aliaksei_Smuhaliou. All rights reserved.
//

import UIKit
import MapKit
import GEOSwift
import GEOSwiftMapKit

class IDPolygon: MKPolygon {
    var norma: Double!
}

class ViewController: UIViewController {

    @IBOutlet private weak var levelLabel: UILabel!
    
    @IBOutlet private weak var mapView: MKMapView!
    
    private var lastUserCoordinate: CLLocationCoordinate2D?
    
    private lazy var locationManager: CLLocationManager = {
        let manager = CLLocationManager()
        manager.delegate = self
        return manager
    }()
    
    private var renders = [MKPolygonRenderer]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        requestLocationUpdates()
        configureMap()
        
        NotificationCenter.default.addObserver(forName: .AppDidReceiveGeoJSONFile, object: nil, queue: nil) { [weak self] (notification) in
            guard let self = self, let url = notification.userInfo?["url"] as? URL else { return }
        
            let features = GeoJSONDecoder.readFeatures(at: url)
            self.clearMap()
            self.addFeatures(features)
        }
    }
    
    private func requestLocationUpdates() {
        let status = CLLocationManager.authorizationStatus()
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .denied, .restricted:
            let alert = UIAlertController(title: "Location Services disabled", message: "Please enable Location Services in Settings", preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default, handler: nil)
            alert.addAction(okAction)
            
            present(alert, animated: true, completion: nil)
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        @unknown default:
            fatalError()
        }
    }
    
    // MARK: - Actions
    
    @IBAction func clearMap(_ sender: Any) {
        clearMap()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let settings = segue.destination as? SettingsViewController {
            settings.delegate = self
        }
    }
    
    // MARK: - Map
    
    private func clearMap() {
        mapView.removeOverlays(mapView.overlays)
        levelLabel.text = "N/A"
        title = ""
    }
    
    private func configureMap() {
        mapView.showsUserLocation = true
    }
    
    private func centerMap(to coordinate: CLLocationCoordinate2D) {
        let latDelta = 0.005
        
        // Think of a span as a tv size, measure from one corner to another
        let span = MKCoordinateSpan(latitudeDelta: fabs(latDelta), longitudeDelta: 0.0)
        let region = MKCoordinateRegion(center: coordinate, span: span)
        mapView.region = region
    }
    
    private func showLevel(at coordinate: CLLocationCoordinate2D) {
        let polygons = mapView.overlays.compactMap { $0 as? IDPolygon }
        let mapPoint: MKMapPoint = MKMapPoint(coordinate)

        for polygon in polygons {
            let polygonRenderer = MKPolygonRenderer(polygon: polygon)
            let polygonViewPoint: CGPoint = polygonRenderer.point(for: mapPoint)
            if polygonRenderer.path.contains(polygonViewPoint) {
                levelLabel.text = String(polygon.norma)
                return
            }
        }
        print("norma: N/A")
        levelLabel.text = "N/A"
    }
        
    private func addFeatures(_ features: [Feature]) {
        for feature in features {
            guard
                case let .multiPolygon(multiPolygon)? = feature.geometry,
                let properties = feature.properties,
                case let .number(level)? = properties["norma_N"] else {
                    continue
            }
            let mkPoligons = multiPolygon.polygons.map { IDPolygon(polygon: $0) }
            mkPoligons.forEach {
                $0.norma = level
            }
            mapView.addOverlays(mkPoligons)
        }
    }
}

extension ViewController: MKMapViewDelegate {

    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        if let overlay = overlay as? IDPolygon {
            let polygonView = MKPolygonRenderer(overlay: overlay)
            polygonView.fillColor = fillColor(ofLevel: overlay.norma)
            polygonView.lineWidth = 1
            polygonView.strokeColor = .red
            return polygonView
        }
        
        return MKOverlayRenderer()
    }
    
    private func fillColor(ofLevel level: Double) -> UIColor {
        let green = CGFloat(level.truncatingRemainder(dividingBy: 255)) / 255

        return UIColor(red: 0.3, green: green, blue: 0.3, alpha: 0.5)
    }
}

extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinate = locations.first?.coordinate else {
            return
        }
        lastUserCoordinate = coordinate
        centerMap(to: coordinate)
        showLevel(at: coordinate)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Failed to find user's location: \(error.localizedDescription)")
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.startUpdatingLocation()
        default:
            break
        }
    }
}

extension ViewController: SettingsViewControllerDelegate {
    
    func settings(_ vc: SettingsViewController, didSelectFeatures features: [Feature], title: String) {
        self.title = title
        clearMap()
        addFeatures(features)
        if let coordinate = lastUserCoordinate {
            showLevel(at: coordinate)
        }
        navigationController?.popViewController(animated: true)
    }
}
