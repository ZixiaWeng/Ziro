//
//  InfoVC.swift
//  Ziro
//
//  Created by Eric on 8/5/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import UIKit
import CoreData

class InfoVC: UIViewController{
	
	@IBOutlet weak var tableView: UITableView!
	var geoPoints: [NSManagedObject] = []
	var tripName: [NSManagedObject] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		self.tableView.delegate = self
		self.tableView.dataSource = self
		title = "Ziro Record"
//		tableView.register(UITableViewCell.self,
//		                   forCellReuseIdentifier: "Cell")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		self.tableView.reloadData()

		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
			return
		}
		
		let managedContext = appDelegate.persistentContainer.viewContext
		
		let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Trip")
		do {
			tripName = try managedContext.fetch(fetchRequest)
		} catch let error as NSError {
			print("Could not fetch. \(error), \(error.userInfo)")
		}
	}
	
	@IBAction func deleteData(_ sender: Any) {
		createDeleteAlert(title: "Delete Your Trip Data",message: "This action is irreversible")
	}
	
	
	@IBAction func refreshData(_ sender: Any) {
		self.tableView.reloadData()
	}


	func createDeleteAlert(title: String, message: String){
		let alertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.alert)
		
		let okAction = UIAlertAction(title: "Yes Please", style: UIAlertActionStyle.default)
		{
			(result : UIAlertAction) -> Void in
			print("You pressed Do it")
			guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
				return
			}
			let managedContext = appDelegate.persistentContainer.viewContext
			let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Location")
			do {
				let results =
					try managedContext.fetch(fetchRequest)
				if results.count != 0 {
					for result in results {
						managedContext.delete(result)
					}
					do {
						try managedContext.save()
					} catch {
						print(error)
					}
				}
				
			} catch let error as NSError {
				print("Could not fetch \(error), \(error.userInfo)")
			}

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

//
//	func save(name: String) {
//		guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
//			return
//		}
//		
//		let managedContext = appDelegate.persistentContainer.viewContext
//		
//		let entity = NSEntityDescription.entity(forEntityName: "Person",
//		                                        in: managedContext)!
//		
//		let person = NSManagedObject(entity: entity,
//		                             insertInto: managedContext)
//		
//		person.setValue(name, forKeyPath: "name")
//		
//		do {
//			try managedContext.save()
//			people.append(person)
//		} catch let error as NSError {
//			print("Could not save. \(error), \(error.userInfo)")
//		}
//	}

}

// MARK: - UITableViewDataSource
extension InfoVC: UITableViewDataSource, UITableViewDelegate {
	
	func tableView(_ tableView: UITableView,
	               numberOfRowsInSection section: Int) -> Int {
		return tripName.count
	}
	
	func tableView(_ tableView: UITableView,
	               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let name = tripName[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "customCell",
		                                         for: indexPath) as! CustomTableViewCell
		
		let a = name.value(forKeyPath: "name") as? String
		if let start = a?.range(of: "("),
			let end  = a?.range(of: ")", range: start.upperBound..<(a?.endIndex)!) {
			let substring = a?[start.upperBound..<end.lowerBound]
			cell.cellName.text = substring
		} else {
			print("invalid input")
		}
		return cell
	}
	
	func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		let storyboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)
		let vc: tripInfoVC = storyboard.instantiateViewController(withIdentifier: "tripInfo") as! tripInfoVC
//		self.present(vc, animated: true, completion: nil)
		tableView.deselectRow(at: indexPath as IndexPath, animated: true)
//		let destination = tripInfoVC() // Your destination
//		destination.geoPoints = geoPoints
		navigationController?.pushViewController(vc, animated: true)
		vc.navigationItem.title = "GeoPoints"
	}
	
}
