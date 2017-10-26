//
//  MapVC.swift
//  Ziro
//
//  Created by Eric on 7/17/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import HealthKit
import CoreData

protocol HandleMapSearch: class {
	func dropPinZoomIn(_ placemark: MKPlacemark)
}

class MapVC: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate, UISearchBarDelegate {
	//Var for basic variables
	var locationManager:CLLocationManager!
	var pointAnnotation:CustomPointAnnotation!
	var pinAnnotationView:MKPinAnnotationView!
	var selectedPin: MKPlacemark?
	var resultSearchController:UISearchController!
	var index = 0, indexA = 0, startRecordOrNot = 0, firstFetchHealth = 0, indexAFlag = 0, UpdateFlag = 0 //flag
	var initialStepsCount = 0  //steps
	var lastLoaction: CLLocationCoordinate2D? = nil
	var destLocation: CLLocation? = nil
	//Var for core data
	var geoPoints: [NSManagedObject] = []
	var tripName: [NSManagedObject] = []

	//Let
	fileprivate let healthKitManager = HealthKitManager.sharedInstance

	let myArray = [UIBarButtonSystemItem.play, UIBarButtonSystemItem.stop]
	let myButtonStateArr = ["Start Recording","Stop Recording"]
	
	@IBOutlet weak var stopButton: UIBarButtonItem!
	@IBOutlet var map: MKMapView!
	@IBOutlet weak var userControlView: UIView!
	@IBOutlet weak var recordButton: UIButton!
	@IBOutlet weak var stepNumberLabel: UILabel!
	
	@IBAction func stop(_ sender: Any) {
		if startRecordOrNot==0 {
			createAlert(title: "ERROR",message: "You Should Press Start Recording First")
			return
		}else{
			//Change the Style of Navigation Bar Item, Judged by Index's Parity
			if index%2 == 0 {
				locationManager.stopUpdatingLocation()
				print("even")
			}
			if index%2 == 1{
				locationManager.startUpdatingLocation()
				print("odd")
			}
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: myArray[index % myArray.count], target: self, action: #selector(MapVC.stop(_:)))
			index+=1
		}
	}
	
	@IBAction func mapTypeSwitchAction(_ sender: Any) {
		switch ((sender as AnyObject).selectedSegmentIndex) {
		case 0:
			map.mapType = .standard
		case 1:
			map.mapType = .satellite
		default:
			map.mapType = .hybrid
		}
	}
	
	@IBAction func searchButton(_ sender: Any) {
		//handle Search
		let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
		resultSearchController = UISearchController(searchResultsController: locationSearchTable)
		resultSearchController?.searchResultsUpdater = locationSearchTable
		
		let searchBar = resultSearchController!.searchBar
		searchBar.sizeToFit()
		searchBar.delegate = self
		searchBar.placeholder = "Search for places"
		navigationItem.titleView = resultSearchController?.searchBar
		
		resultSearchController?.hidesNavigationBarDuringPresentation = false
		resultSearchController?.dimsBackgroundDuringPresentation = true
		definesPresentationContext = true
		locationSearchTable.mapView = map
		locationSearchTable.handleMapSearchDelegate = self
	}
	
	@IBAction func recordAction(_ sender: Any) {
		//start
		if indexA%2 == 0 {
			//flag
			startRecordOrNot = 1
			self.stepNumberLabel.text = "0 steps"
			locationManager.allowsBackgroundLocationUpdates = true
			if CLLocationManager.locationServicesEnabled() {
				locationManager.startUpdatingLocation()
			}
			DispatchQueue.main.async {
				self.locationManager.startUpdatingLocation()
			}
			indexA+=1
			createAskTripnameAlert(title: "Create Your Trip", message: "Enter Your Trip Name -v-")
			print("start!")
		}
		//stop
		else if indexA%2 == 1{
			createCancelAlert(title: "Are You Sure?", message: "This App will not record your actions anymore")
		}

		recordButton.setTitle(myButtonStateArr[indexA % myArray.count], for: .normal)
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		recordButton.layer.cornerRadius = 5
		
		map.delegate = self
		
		requestHealthKitAuthorization()
		locationManager = CLLocationManager()
		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.requestWhenInUseAuthorization()

	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
	}
	
	func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
		//Hide the Search Bar
		navigationItem.titleView = nil
	}
	
	func getDirections(){
		print("trigger getDirections")
		guard let selectedPin = selectedPin else {return}
		let mapItem = MKMapItem(placemark: selectedPin)
		let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
		mapItem.openInMaps(launchOptions:launchOptions)
	}
	
	
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		let userLocation:CLLocation = locations[0]
		let latitude:CLLocationDegrees = userLocation.coordinate.latitude
		let longtitude:CLLocationDegrees = userLocation.coordinate.longitude
		let latDelta:CLLocationDegrees = 0.01
		let lonDelta:CLLocationDegrees = 0.01
		let span:MKCoordinateSpan = MKCoordinateSpanMake(latDelta, lonDelta)
		let location:CLLocationCoordinate2D = CLLocationCoordinate2DMake(latitude, longtitude)
		let region:MKCoordinateRegion = MKCoordinateRegionMake(location, span)
		if UpdateFlag == 0 {
			addSingleAnnotation(subtitle: "Start Point", userLocation: userLocation)
		}
		else if UpdateFlag == 1{
			let polyline = MKPolyline(coordinates: [lastLoaction!,location], count: 2)
			self.map.add(polyline)
		}
		else if UpdateFlag == 2{
			addSingleAnnotation(subtitle: "Destination", userLocation: userLocation)
		}
		lastLoaction = location
		destLocation = userLocation
		UpdateFlag = 1
		

		map.setRegion(region, animated: true)


		//Update and Print stepsCount
		getTodaysSteps(completion: { (stepRetrieved) in
			print(Int(stepRetrieved - 0))
		})
		
		let date = Date()
		let calendar = Calendar.current
		let hour = calendar.component(.hour, from: date)
		let minutes = calendar.component(.minute, from: date)
		let seconds = calendar.component(.second, from: date)
		print("time = \(hour):\(minutes):\(seconds)")
		print(latitude, longtitude)
		
		//Save to Local Data
		self.save(name: "\(userLocation.coordinate.latitude),\(userLocation.coordinate.longitude)", EntityName: "Location", KeyPathName: "geoPoint", Object: geoPoints)
	}

	func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
		if overlay is MKCircle {
			let renderer = MKCircleRenderer(overlay: overlay)
			renderer.fillColor = UIColor.black.withAlphaComponent(0.5)
			renderer.strokeColor = UIColor.blue
			renderer.lineWidth = 2
			return renderer
			
		} else if overlay is MKPolyline {
			let renderer = MKPolylineRenderer(overlay: overlay)
			renderer.strokeColor = UIColor.blue
			renderer.lineWidth = 3
			return renderer
			
		}
		return MKOverlayRenderer()
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
		annotationView?.isEnabled = true
		annotationView?.canShowCallout = true
		let smallSquare = CGSize(width: 30, height: 30)
		let button = UIButton(frame: CGRect(origin: CGPoint(x: 0, y: 0), size: smallSquare))
		button.setBackgroundImage(UIImage(named: "ann"), for: .normal)
		button.addTarget(self, action: #selector(MapVC.getDirections), for: .touchUpInside)
		annotationView?.leftCalloutAccessoryView = button
		return annotationView
	}
	
	//Core Data Helper Function
	func save(name: String, EntityName: String, KeyPathName: String, Object: [NSManagedObject]) {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		
		let entity = NSEntityDescription.entity(forEntityName: EntityName,
		                                        in: managedContext)!
		
		let person = NSManagedObject(entity: entity,
		                             insertInto: managedContext)
		
		person.setValue(name, forKeyPath: KeyPathName)
		
		do {
			try managedContext.save()
			geoPoints.append(person)
		} catch let error as NSError {
			print("Could not save. \(error), \(error.userInfo)")
		}
	}

	func saveName(name: String, EntityName: String, KeyPathName: String, Object: [NSManagedObject]) {
		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		
		let entity = NSEntityDescription.entity(forEntityName: EntityName,
		                                        in: managedContext)!
		
		let person = NSManagedObject(entity: entity,
		                             insertInto: managedContext)
		
		person.setValue(name, forKeyPath: KeyPathName)
		
		do {
			try managedContext.save()
			geoPoints.append(person)
		} catch let error as NSError {
			print("Could not save. \(error), \(error.userInfo)")
		}
	}

	func addSingleAnnotation(subtitle: String, userLocation: CLLocation) {
		
		pointAnnotation = CustomPointAnnotation()
		pointAnnotation.imageName = "ann"
		pointAnnotation.coordinate.latitude = userLocation.coordinate.latitude
		pointAnnotation.coordinate.longitude = userLocation.coordinate.longitude
		pointAnnotation.title = "User Name"
		pointAnnotation.subtitle = subtitle
		pinAnnotationView = MKPinAnnotationView(annotation: pointAnnotation, reuseIdentifier: "pin")
		map.addAnnotation(pinAnnotationView.annotation!)
		selectedPin = pinAnnotationView.annotation! as? MKPlacemark
	}
	
	//Health Helper Function
	func getTodaysSteps(completion: @escaping (Double) -> Void) {
		let stepsQuantityType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
		
		let now = Date()
		let startOfDay = Calendar.current.startOfDay(for: now)
		let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

		let query = HKStatisticsQuery(quantityType: stepsQuantityType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
			var resultCount = 0.0
			
			guard let result = result else {
				print("Failed to fetch steps = \(error?.localizedDescription ?? "N/A")")
				completion(resultCount)
				return
			}
			
			if let sum = result.sumQuantity() {
				resultCount = sum.doubleValue(for: HKUnit.count())
				if self.firstFetchHealth == 0{
					self.initialStepsCount = Int(resultCount)
					print(self.initialStepsCount, "第一次记录步数")
				    self.firstFetchHealth = 1
				}
				else{
					self.stepNumberLabel.text = "\(Int(resultCount) - self.initialStepsCount) Steps"
					print(Int(resultCount) - self.initialStepsCount, "非第一次记录步数")

				}
			}
			
			DispatchQueue.main.async {
				completion(resultCount)
			}
		}
		
		healthKitManager.healthStore?.execute(query)
	}
	
	
}


extension MapVC: HandleMapSearch{

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
		map.addAnnotation(annotation)
		let span = MKCoordinateSpanMake(0.05, 0.05)
		let region = MKCoordinateRegionMake(placemark.coordinate, span)
		map.setRegion(region, animated: true)
	}
	
}

private extension MapVC {
	func requestHealthKitAuthorization() {
		let dataTypesToRead = NSSet(objects: healthKitManager.stepsCount as Any)
		healthKitManager.healthStore?.requestAuthorization(toShare: nil, read: dataTypesToRead as? Set<HKObjectType>, completion: { [unowned self] (success, error) in
			if success {
				self.getTodaysSteps(completion: { (stepRetrieved) in
					print(Int(stepRetrieved - 0))
				})
			} else {
				print(error.debugDescription)
			}
		})
	}
	// Alert Helper Function
	func createAlert(title: String, message: String){
		let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		
		let okAction = UIAlertAction(title: "I got it", style: UIAlertActionStyle.default)
		{
			(result : UIAlertAction) -> Void in
			print("You pressed OK")
		}
		
		alertController.addAction(okAction)
		self.present(alertController, animated: true, completion: nil)
	}
	func createCancelAlert(title: String, message: String){
		let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		
		let okAction = UIAlertAction(title: "Do it", style: UIAlertActionStyle.default)
		{
			(result : UIAlertAction) -> Void in
			print("You pressed Do it")
			//flag
			self.startRecordOrNot = 0
			self.UpdateFlag = 2
			
			//如果左上角是play 改变为x
			self.index = 0;	self.indexA = 0
			self.navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: self.myArray[1 % self.myArray.count], target: self, action: #selector(MapVC.stop(_:)))
			self.recordButton.setTitle(self.myButtonStateArr[0 % self.myArray.count], for: .normal)
			self.locationManager.stopUpdatingLocation()
			self.addSingleAnnotation(subtitle: "Destination", userLocation: self.destLocation!)
//			self.map.removeAnnotations(self.map.annotations)
			self.stepNumberLabel.text = "Step Number"
			return
		}
		
		let cancelAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel)
		{
			(result : UIAlertAction) -> Void in
			print("You pressed CANCEL")
		}
		
		alertController.addAction(okAction)
		alertController.addAction(cancelAction)
		self.present(alertController, animated: true, completion: nil)
	}
	func createAskTripnameAlert(title: String, message:String){
		let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
		
		let saveAction = UIAlertAction(title: "Save", style: .default, handler: {
			alert -> Void in
			
			let firstTextField = alertController.textFields![0] as UITextField
			
			print("firstName \(String(describing: firstTextField.text))")
			self.saveName(name: "\(String(describing: firstTextField.text))", EntityName: "Trip", KeyPathName: "name", Object: self.tripName)
		})
		
		let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: {
			(action : UIAlertAction!) -> Void in
			self.saveName(name: "Default Trip", EntityName: "Trip", KeyPathName: "name", Object: self.tripName)
		})
		
		alertController.addTextField { (textField : UITextField!) -> Void in
			textField.placeholder = "Enter Trip Name"
		}
		
		alertController.addAction(saveAction)
		alertController.addAction(cancelAction)
		self.present(alertController, animated: true, completion: nil)
	}

}

