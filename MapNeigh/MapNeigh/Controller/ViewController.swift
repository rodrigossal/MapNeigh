//
//  ViewController.swift
//  MapNeigh
//
//  Created by Rodrigo Salles Stefani on 20/02/18.
//  Copyright © 2018 Rodrigo Salles Stefani. All rights reserved.
//

import UIKit
import MapKit
import SwifterSwift
import UIKit.UIGestureRecognizerSubclass

class ViewController: UIViewController, CLLocationManagerDelegate {

    
    let locationManager = CLLocationManager()
    
    @IBOutlet weak var map: MKMapView!
    
    var activeLocation: CLLocation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

        let  uilgr = UILongPressGestureRecognizer(target: self, action: #selector(self.addLocationWithLongPress(_:)))
        
        
        
        map.addGestureRecognizer(uilgr)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    override func viewWillAppear(_ animated: Bool) {
        locationManager.requestLocation()
        map.showsUserLocation = true
    }
    
    @objc func addLocationWithLongPress(_ recognier: UIGestureRecognizer){
        
        if recognier.state == .began{
            let touchPoint = recognier.location(in: map)
            let coordinates = map.convert(touchPoint, toCoordinateFrom: map)
            let newLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
            let annotation = MKPointAnnotation()
            annotation.coordinate = coordinates
            if let location = activeLocation{
                let distance = location.distance(from: newLocation)
                annotation.title = "Distância: \(String(format: "%.2f", distance/1000)) KM"
            }
            map.addAnnotation(annotation)
        }
        
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        activeLocation = locations[locations.count - 1]
        let region = MKCoordinateRegionMakeWithDistance((activeLocation?.coordinate)!, 200000, 200000)
        map.setRegion(region, animated: true)
    }
    
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Deu Ruim")
    }
    
    
}

