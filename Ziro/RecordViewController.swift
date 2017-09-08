//
//  RecordViewController.swift
//  Ziro
//
//  Created by Eric on 8/20/17.
//  Copyright © 2017 Zixia. All rights reserved.
//


import UIKit
import MapKit
import CoreData
import CoreLocation


class RecordViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
	
	@IBOutlet weak var mapView: MKMapView!
	var geoPoints: [NSManagedObject] = []
	var pointAnnotation:CustomPointAnnotation!
	var pinAnnotationView:MKPinAnnotationView!
	var selectedPin: MKPlacemark?
	var locationManager:CLLocationManager!
	var lastLa: Double = 0.0
	var lastLon: Double = 0.0

	@IBOutlet weak var loadButton: UIBarButtonItem!

	
	@IBAction func removeAnnotations(_ sender: Any) {
		self.mapView.removeAnnotations(self.mapView.annotations)
		
		self.navigationItem.rightBarButtonItem?.tintColor = self.view.tintColor

		self.navigationItem.rightBarButtonItem?.isEnabled = true

	}
	
	@IBAction func loadAnnotations(_ sender: Any) {
		
		for geoPoint in geoPoints{
			var geoString = geoPoint.value(forKeyPath: "geoPoint") as? String
			var myStringArr = geoString?.characters.split{$0 == ","}.map(String.init)
			let lat = myStringArr?[0]
			let lon = myStringArr?[1]
			pointAnnotation = CustomPointAnnotation()
			pointAnnotation.imageName = "ann"
			pointAnnotation.coordinate.latitude = (lat! as NSString).doubleValue
			pointAnnotation.coordinate.longitude = (lon! as NSString).doubleValue
			pointAnnotation.title = "Zzzzix"
			pointAnnotation.subtitle = "last trip"
			pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: "pin")
			mapView.addAnnotation(pinAnnotationView.annotation!)
			selectedPin = pinAnnotationView.annotation! as? MKPlacemark
			lastLa = (lat! as NSString).doubleValue
			lastLon = (lon! as NSString).doubleValue
		}
		self.navigationItem.rightBarButtonItem?.tintColor = .clear
		self.navigationItem.rightBarButtonItem?.isEnabled = false

		let latDelta:CLLocationDegrees = 0.01
		let lonDelta:CLLocationDegrees = 0.01
		let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
		let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(lastLa, lastLon)
		let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
		
		mapView.setRegion(region, animated: true)

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
		do {
			geoPoints = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("Could not fetch. \(error), \(error.userInfo)")
		}
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		// Do any additional setup after loading the view, typically from a nib.
		mapView.delegate = self
		
		locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()

	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	func getDirections(){
		print("trigger getDirections")
		guard let selectedPin = selectedPin else {return}
		let mapItem = MKMapItem(placemark: selectedPin)
		let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
		mapItem.openInMaps(launchOptions:launchOptions)
	}
	
	func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
		guard !annotation.isKind(of: MKUserLocation.self) else {
			return nil
		}
		
		let annotationIdentifier = "pin"
		
		var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: annotationIdentifier)
		
		if annotationView == nil
		{
			annotationView = MKAnnotationView(annotation: annotation, reuseIdentifier: annotationIdentifier)
			annotationView!.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
			annotationView!.canShowCallout = true
		}
		else
		{
			annotationView!.annotation = annotation
		}
		
		annotationView!.image = UIImage(named: "annn")
		annotationView?.canShowCallout = true
		let smallSquare = CGSize(width: 30, height: 30)
		let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: smallSquare))
		button.setBackgroundImage(UIImage(named: "ann"), for: .normal)
		button.addTarget(self, action: #selector(RecordViewController.getDirections), for: .touchUpInside)
		annotationView?.leftCalloutAccessoryView = button
		return annotationView
	}

}


extension RecordViewController: HandleMapSearch{
	
	func dropPinZoomIn(_ placemark:MKPlacemark){
		// cache the pin
		selectedPin = placemark
		// clear existing pins
		let annotation = MKPointAnnotation()
		annotation.coordinate = placemark.coordinate
		annotation.title = placemark.name
		if let city = placemark.locality,
			let state = placemark.administrativeArea {
			annotation.subtitle = "\(city) \(state)"
		}
		mapView.addAnnotation(annotation)
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegionMake(placemark.coordinate, span)
		mapView.setRegion(region, animated: true)
	}
}
