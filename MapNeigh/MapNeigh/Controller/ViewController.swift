//
//  ViewController.swift
//  MapNeigh
//
//  Created by Rodrigo Salles Stefani on 20/02/18.
//  Copyright © 2018 Rodrigo Salles Stefani. All rights reserved.
//

import UIKit
import CoreML
import Vision
import MapKit
import SwifterSwift
import CameraManager


enum State {
    case closed
    case open
    
    var opposite: State {
        return self == .open ? .closed : .open
    }
}

class ViewController: UIViewController, CLLocationManagerDelegate {

    
    @IBOutlet weak var face: UIImageView!
    let locationManager = CLLocationManager()
    
    var activeLocation: CLLocation?
    
    let cameraManager = CameraManager()
    
    @IBOutlet weak var map: MKMapView!

    @IBOutlet weak var cameraPreview: UIView!
    
    @IBOutlet weak var swipeCamera: NSLayoutConstraint!
    
    @IBOutlet weak var cameraView: UIView!
    
    @IBOutlet weak var puxeView: UIView!

    @IBOutlet weak var resultLabel: UILabel!
    
    var viewOffset: CGFloat = 265
    var timer = Timer()
    let vowels: [Character] = ["a", "e", "i", "o", "u"]
    
    //Array with all animators for the view
    var runningAnimators: [UIViewPropertyAnimator] = []
    
    //Current state of comments view
    var state: State = .closed

    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupMap()
        setupCamera()
        setupViews()
        Resources.init()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        locationManager.requestLocation()
        map.showsUserLocation = true
        setupPic()
    }
    override func viewWillDisappear(_ animated: Bool) {
    }
    
    func setupViews() {
        swipeCamera.constant = 0
        
        //pan gesture is responsible for dragging
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.onDrag(_:)))
        //self.puxeView.addGestureRecognizer(panGesture)
        self.cameraView.addGestureRecognizer(panGesture)
        
        //create tap gesture recognizer and add to view
        //view will open and close on tap
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.onTap(_:)))
        self.puxeView.addGestureRecognizer(tapGesture)
        self.resultLabel.addGestureRecognizer(tapGesture)
        
    }
    
    func setupMap(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()
        
        let  uilgr = UILongPressGestureRecognizer(target: self, action: #selector(self.addLocationWithLongPress(_:)))
        map.addGestureRecognizer(uilgr)
    }
    
    func setupCamera(){
        cameraManager.addPreviewLayerToView(self.cameraPreview)
        cameraManager.cameraDevice = .front
        cameraManager.shouldEnableTapToFocus = false
        cameraManager.shouldEnablePinchToZoom = false
        cameraManager.showAccessPermissionPopupAutomatically = true
        cameraManager.animateShutter = false
        cameraManager.writeFilesToPhoneLibrary = false
        
        self.cameraPreview.layer.cornerRadius = 100
        
    }
    
    func setupPic(){
        //takePicture()
        timer = Timer.scheduledTimer(timeInterval: 3, target: self, selector: (#selector(self.takePicture)), userInfo: nil, repeats: true)
    }
    
    @objc func takePicture(){
        var myImage : UIImage!
        cameraManager.capturePictureWithCompletion({ (image, error) -> Void in
            myImage = image
                
            
            if myImage != nil{
                guard let ciImage = CIImage(image: myImage) else {
                    fatalError("couldn't convert UIImage to CIImage")
                }
                
                self.detectScene(image: ciImage)
            } else{
                self.takePicture()
            }
            
        })
        
    }

    
    func animateIfNeeded(to state: State, duration: TimeInterval) {
        
        //if there is animators running, ignore
        guard runningAnimators.isEmpty else { return }
        
        setupCamera()
        
        //Creates a basic animator to take care of the states of the view
        let basicAnimator = UIViewPropertyAnimator(duration: duration, curve: .easeOut, animations: nil)
        
        //Add animations to the animator
        //Related to view position, corner radius and icon alpha
        //Just use the desired value for each state (closed or open)
        basicAnimator.addAnimations {
            switch state {
            case .open:
                self.swipeCamera.constant = self.viewOffset
                self.cameraView.layer.cornerRadius = 60
            case .closed:
                self.swipeCamera.constant = 0
                self.cameraView.layer.cornerRadius = 0
            }
            self.view.layoutIfNeeded()
        }
        basicAnimator.addAnimations{
            switch state{
            case .open:
                self.puxeView.alpha = 0
                self.puxeView.layer.cornerRadius = 60
            case .closed:
                self.puxeView.alpha = 1
                self.puxeView.layer.cornerRadius = 0
            }
        }
        
        
        basicAnimator.addCompletion { position in
            self.runningAnimators.removeAll()
            self.state = self.state.opposite //change the current state to the opposite
        }
        
        
        runningAnimators.append(basicAnimator)
        
    }
    
    
    @objc func onDrag(_ gesture: UIPanGestureRecognizer) {
        
        switch gesture.state {
        case .began:
            //create animations to desired state
            animateIfNeeded(to: state.opposite, duration: 0.4)
        case .changed:
            //calculates the percent of completion and sets it to all running animators
            let translation = gesture.translation(in: cameraView)
            let fraction = abs(translation.y / viewOffset)
            
            runningAnimators.forEach { animator in
                animator.fractionComplete = fraction
            }
        case .ended:
            //finish running animations to desired state
            runningAnimators.forEach { $0.continueAnimation(withTimingParameters: nil, durationFactor: 0) }
        default:
            break
        }
        
    }
    
    @objc func onTap(_ gesture: UITapGestureRecognizer) {
        
        //create animations and
        animateIfNeeded(to: state.opposite, duration: 0.4)
        runningAnimators.forEach { $0.startAnimation() }
        
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
        let region = MKCoordinateRegionMakeWithDistance((activeLocation?.coordinate)!, 2000, 2000)
        map.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Deu Ruim")
    }
    

    
    
    
    func detectScene(image: CIImage) {
        resultLabel.text = "detecting scene..."
        
        // Load the ML model through its generated class
        guard let model = try? VNCoreMLModel(for: CNNEmotions().model) else {
            fatalError("can't load Places ML model")
        }
        // Create a Vision request with completion handler
        let request = VNCoreMLRequest(model: model) { [weak self] request, error in
            guard let results = request.results as? [VNClassificationObservation],
                let topResult = results.first else {
                    fatalError("unexpected result type from VNCoreMLRequest")
            }
            
            // Update UI on main queue
            let article = (self?.vowels.contains(topResult.identifier.first!))! ? "an" : "a"
            DispatchQueue.main.async { [weak self] in
                self?.resultLabel.text = "\(Int(topResult.confidence * 100))% it's \(article) \(topResult.identifier)"
            }
        }
        
        // Run the Core ML GoogLeNetPlaces classifier on global dispatch queue
        let handler = VNImageRequestHandler(ciImage: image)
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                try handler.perform([request])
            } catch {
                print(error)
            }
        }
        
        
        
    }

    


    
    
    
    
    
}

