//
//  ViewController.swift
//  Besepeda
//
//  Created by Ivan Winata on 21/11/20.
//

import UIKit
import MapKit
import CoreLocation
import AVFoundation

class ViewController: UIViewController, CLLocationManagerDelegate {

    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var timeLabelDone: UILabel!
    @IBOutlet weak var distanceLabelDone: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var hatihatiLabel: UILabel!
    
    let manager = CLLocationManager()
    
    var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    func registerBackgroundTask() {
      backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
        self?.endBackgroundTask()
      }
      assert(backgroundTask != .invalid)
    }
      
    func endBackgroundTask() {
      print("Background task ended.")
      UIApplication.shared.endBackgroundTask(backgroundTask)
      backgroundTask = .invalid
    }

//    var run1: Run!
//    private var run: Run?
    private var seconds = 0
    private var timer: Timer?
    private var distance = Measurement(value: 0, unit: UnitLength.kilometers)
    private var locationList: [CLLocation] = []
    var timerSpeech = Timer()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        // Do any additional setup after loading the view.
        stopButton.isHidden = true
        titleLabel.text = "Redi? Yok!"
        
    }
        
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        timer?.invalidate()
        manager.stopUpdatingLocation()
        }
        
    
    func eachSecond() {
      seconds += 1
      updateDisplay()
    }

    func updateDisplay() {
      let formattedDistance = FormatDisplay.distance(distance)
      let formattedTime = FormatDisplay.time(seconds)

        
      distanceLabel.text = "\(formattedDistance)"
      timeLabel.text = "\(formattedTime)"
        distanceLabelDone.text = "\(formattedDistance)"
        timeLabelDone.text = "\(formattedTime)"
        
    
    }
    private func configureView(){
        startButton.layer.cornerRadius = 12
        stopButton.layer.cornerRadius = 12
        timeLabel.isHidden = true
        distanceLabel.isHidden = true
        timeLabelDone.isHidden = true
        distanceLabelDone.isHidden = true
        hatihatiLabel.isHidden = true
        
        
       
    }
    private func startRun(){
        startButton.isHidden = true
        stopButton.isHidden = false
        mapView.isHidden = true
        timeLabel.isHidden = false
        distanceLabel.isHidden = false
        timeLabelDone.isHidden = true
        distanceLabelDone.isHidden = true
        hatihatiLabel.isHidden = false
        titleLabel.isHidden = true
        
        seconds = 0
        distance = Measurement(value: 0, unit: UnitLength.meters)
        locationList.removeAll()
        updateDisplay()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
          self.eachSecond()
        }
        startLocationUpdates()
        
        timerSpeech = Timer.scheduledTimer(timeInterval: 10, target: self, selector: #selector(ngomong), userInfo: nil, repeats: true)
        
        let string = "Gak usah sok ngebut, entar jatoh, nangis kau!"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
        

        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)

    }
    
    @objc func ngomong(){
        let utterance = AVSpeechUtterance(string: "\(FormatDisplay.distance(distance))")
        utterance.voice = AVSpeechSynthesisVoice(language: "en-AU")
        

        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    }
    
    
    
    private func stopRun(){
        startButton.isHidden = false
        stopButton.isHidden = true
        mapView.isHidden = false
        timer?.invalidate()
        timerSpeech.invalidate()
        distanceLabel.isHidden = true
        timeLabel.isHidden = true
        timeLabelDone.isHidden = false
        distanceLabelDone.isHidden = false
        titleLabel.isHidden = false
        titleLabel.text = "Ya udah, istirahat sana!"
        hatihatiLabel.isHidden = true
        
        let string = "Jangan lupa minum air, dasar ampas!"
        let utterance = AVSpeechUtterance(string: string)
        utterance.voice = AVSpeechSynthesisVoice(language: "id-ID")
        

        let synth = AVSpeechSynthesizer()
        synth.speak(utterance)
    
    }
    
    @IBAction func startTapped(_ sender: Any) {
    startRun()
    }
    
    @IBAction func stopTapped(_ sender: Any) {
        let alertController = UIAlertController(title: "Udahan?",
                                                message: "Baru segini udahan? Lembek!",
                                                preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Lanjut deh", style: .cancel))
        alertController.addAction(UIAlertAction(title: "Iya, udahan. Capek cuy..", style: .default) { _ in
          self.stopRun()
        })
        present(alertController, animated: true)
    }
    
// MARK:   Map
    override func viewDidAppear(_ animated: Bool) {
//        super.viewDidAppear(animated)
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            manager.stopUpdatingLocation()

            render(location)
        }
        for newLocation in locations {
          let howRecent = newLocation.timestamp.timeIntervalSinceNow
          guard newLocation.horizontalAccuracy < 20 && abs(howRecent) < 10 else { continue }

          if let lastLocation = locationList.last {
            let delta = newLocation.distance(from: lastLocation)
            distance = distance + Measurement(value: delta, unit: UnitLength.meters)
          }

          locationList.append(newLocation)
        }
      }
    
    private func startLocationUpdates() {
      manager.delegate = self
      manager.activityType = .fitness
      manager.distanceFilter = 10
      manager.startUpdatingLocation()
    }

    func render(_ location: CLLocation){
        
        let coordinate = CLLocationCoordinate2D(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude)
        
        let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
        
        let region = MKCoordinateRegion(center: coordinate, span: span)

        mapView.setRegion(region, animated: true)
        
        let pin = MKPointAnnotation()
        pin.coordinate = coordinate
        mapView.addAnnotation(pin)
        
    }
    
   
    
   
}

