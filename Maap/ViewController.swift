//
//  ViewController.swift
//  Maap
//
//  Created by Gerardo Villarroel on 22-08-16.
//  Copyright © 2016 Gerardo Villarroel. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapa: MKMapView!
    @IBOutlet weak var distanciaRecorrida: UILabel!
    @IBOutlet weak var velocidad: UILabel!
    @IBOutlet weak var duracion: UILabel!
    @IBOutlet weak var zoomSlider: UISlider!
    
    private var localizacionInicial = CLLocationCoordinate2D()
    private var newLocation = CLLocation()
    private var localizacionActual = CLLocationCoordinate2D()
    private let manejador = CLLocationManager()
    private var latitudDistance: CLLocationDegrees = 0.01
    private var longitudDistance: CLLocationDegrees = 0.01
    private var distancia = 0.0
    private var distanciaTotal = 0.0
    private var nuevaLocalizacion = false
    private var primerPin = false
    private var timer = NSTimer()
    private var seconds: NSTimeInterval = 0
    private var alturaCamara: CLLocationDistance = 1000
    
    @IBAction func reset() {
        resetAll()
    }
    
    private func resetAll() {
        velocidad.text = "0 Km/h"
        distanciaRecorrida.text = "0.0 Km"
        duracion.text = "00:00 min"
        distancia = 0.0
        distanciaTotal = 0.0
        nuevaLocalizacion = false
        mapa.setCenterCoordinate(localizacionActual, animated: true)
        let allAnnotations = mapa.annotations
        mapa.removeAnnotations(allAnnotations)
        localizacionInicial = localizacionActual
        timer.invalidate()
        timerInit()
        seconds = 0
    }
    
    private func timerInit() {
        timer = NSTimer.scheduledTimerWithTimeInterval(1, target: self, selector: #selector(ViewController.interval), userInfo: nil, repeats: true)
    }
    
    @objc private func interval() {
        seconds += 1
        duracion.text = stringFromTimeInterval(seconds) + " min"
        cameraSetup()
        mapa.setCenterCoordinate(localizacionActual, animated: true)
    }
    
    private func stringFromTimeInterval(interval: NSTimeInterval)-> String {
        let ti = NSInteger(interval)
        let seconds = ti % 60
        let minutes = (ti / 60) % 60
        
        return String(format: "%0.2d:%0.2d", minutes, seconds)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapa.delegate = self
        manejador.delegate = self
        manejador.desiredAccuracy = kCLLocationAccuracyBest
        manejador.requestWhenInUseAuthorization()
        
        localizacionInicial = CLLocationCoordinate2DMake(localizacion().latitud, localizacion().longitud)
        let mapRegionView = MKCoordinateRegionMake(localizacionInicial, MKCoordinateSpanMake(latitudDistance, longitudDistance))
        mapa.setRegion(mapRegionView, animated: true)
        
        mapa.showsCompass = true
    }

    private func localizacion()-> (latitud: CLLocationDegrees, longitud: CLLocationDegrees) {
        if manejador.location != nil {
            return (manejador.location!.coordinate.latitude, manejador.location!.coordinate.longitude)
        } else {
            return (37.785834, -122.406417)
        }
    }
    
    private func colocarPin(loc2: CLLocation) {
        let pin = MKPointAnnotation()
        pin.title = "\(localizacionActual.latitude), \(localizacionActual.longitude)"
        pin.subtitle = String(format: "%.2f", distancia) + " Mts."
        
        newLocation = loc2
        pin.coordinate = localizacionActual
        mapa.addAnnotation(pin)
        
        distanciaTotal += distancia
        distanciaRecorrida.text = String(format: "%.2f", distanciaTotal / 1000) + " Km."
    }
    
    @objc internal func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse {
            manejador.startUpdatingLocation()
            mapa.showsUserLocation = true
        } else {
            manejador.stopUpdatingLocation()
            mapa.showsUserLocation = false
        }
    }
    
    @objc internal func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        localizacionActual = CLLocationCoordinate2DMake(manejador.location!.coordinate.latitude, manejador.location!.coordinate.longitude)
        
        var loc1 = CLLocation()
        if !nuevaLocalizacion {
            loc1 = CLLocation(latitude: localizacionInicial.latitude, longitude: localizacionInicial.longitude)
            nuevaLocalizacion = true
        } else {
            loc1 = newLocation
        }
        let loc2 = CLLocation(latitude: localizacionActual.latitude, longitude: localizacionActual.longitude)
        distancia = loc2.distanceFromLocation(loc1)

        if distancia > 50 {
            colocarPin(loc2)
            if !primerPin {
                primerPin = true
                resetAll()
            }
        }
        let speed = manejador.location!.speed * 3.6
        if speed > 0 {
            velocidad.text = String(format: "%.0f", speed) + " Km/h"
        }
    }
    
    @IBAction func zoom(sender: UISlider) {
        alturaCamara = CLLocationDistance(sender.value)
        cameraSetup()
    }
    
    @IBAction func segmentControlChange(sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 1:
            mapa.mapType = MKMapType.SatelliteFlyover
        case 2:
            mapa.mapType = MKMapType.HybridFlyover
        default:
            mapa.mapType = MKMapType.Standard
        }
        cameraSetup()
    }
    
    private func cameraSetup() {
        let coordenadas = localizacionActual
        let altura = alturaCamara
        let angulo: CGFloat = 45
        let posicionDelMapaSegunElNorte = manejador.location!.course
        
        let camera = MKMapCamera(lookingAtCenterCoordinate: coordenadas, fromDistance: altura, pitch: angulo, heading: posicionDelMapaSegunElNorte)
        mapa.setCamera(camera, animated: true)
    }
}