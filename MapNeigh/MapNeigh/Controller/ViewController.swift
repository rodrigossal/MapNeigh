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
import Firebase


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
    
    var ref : DatabaseReference!
    
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
        ref = Database.database().reference()
        setupLoading()
        setupPins()
        
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
    
    func setupLoading(){
        let alert = UIAlertController(title: nil, message: "Looking for you...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
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
        //self.resultLabel.addGestureRecognizer(tapGesture)
        
    }
    
    func setupMap(){
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 1000
        locationManager.delegate = self
        locationManager.requestAlwaysAuthorization()

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
    
    func setupPins(){

        var feeling = UserDefaults.standard.array(forKey: "feeling")
        var posLa = UserDefaults.standard.array(forKey: "posLa")
        var posLo = UserDefaults.standard.array(forKey: "posLo")
        
        var pin : CLLocation?
        
        if feeling!.count <= 0{
            return
        }
        for i in 0...(feeling!.count)-1{
            print(i)
            pin = CLLocation.init(latitude: posLa![i] as! CLLocationDegrees, longitude: posLo![i] as! CLLocationDegrees)
            let annotation = MKPointAnnotation()
            annotation.coordinate = (pin?.coordinate)!
            annotation.title = feeling![i] as? String
            map.addAnnotation(annotation)
        }
        
        
    }
    
    func setupPic(){
        //takePicture()
        timer = Timer.scheduledTimer(timeInterval: 2, target: self, selector: (#selector(self.takePicture)), userInfo: nil, repeats: true)
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
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        activeLocation = locations[locations.count - 1]
        dismiss(animated: false, completion: nil)
        let region = MKCoordinateRegionMakeWithDistance((activeLocation?.coordinate)!, 2000, 2000)
        map.setRegion(region, animated: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Deu Ruim")
    }
    

    
    
    
    func detectScene(image: CIImage) {
        
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
            DispatchQueue.main.async { [weak self] in
                self?.resultLabel.text = "\(topResult.identifier)"
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

    @IBAction func buttonShare(_ sender: Any) {
        
        animateIfNeeded(to: state.opposite, duration: 0.4)
        
        let region = MKCoordinateRegionMakeWithDistance((activeLocation?.coordinate)!, 1000, 1000)
        map.setRegion(region, animated: true)
        
        if activeLocation != nil{
            let newLocation = activeLocation
            let annotation = MKPointAnnotation()
            annotation.coordinate = (activeLocation?.coordinate)!
            if let location = activeLocation{
                let distance = location.distance(from: newLocation!)
                annotation.title = resultLabel.text
            }
            map.addAnnotation(annotation)

            var feeling = UserDefaults.standard.array(forKey: "feeling")
            var posLa = UserDefaults.standard.array(forKey: "posLa")
            var posLo = UserDefaults.standard.array(forKey: "posLo")
            
            feeling?.append(resultLabel.text)
            posLa?.append(activeLocation?.coordinate.latitude)
            posLo?.append(activeLocation?.coordinate.longitude)
            
            UserDefaults.standard.set(feeling, forKey: "feeling")
            UserDefaults.standard.set(posLa, forKey: "posLa")
            UserDefaults.standard.set(posLo, forKey: "posLo")
            
            
        
            self.ref.child("users").child("0").child("emotion").setValue(resultLabel.text)
            self.ref.child("users").child("0").child("posLatitude").setValue(activeLocation?.coordinate.latitude)
        self.ref.child("users").child("0").child("posLongitude").setValue(activeLocation?.coordinate.longitude )
        }
        
        
    }
    


    
    
    
    
    
}

