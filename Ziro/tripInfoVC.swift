//
//  tripInfoVC.swift
//  Ziro
//
//  Created by Eric on 8/5/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import UIKit
import CoreData

class tripInfoVC: UIViewController, UITableViewDataSource, UITableViewDelegate{
	@IBOutlet weak var tableView: UITableView!
	var geoPoints: [NSManagedObject] = []
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register(UITableViewCell.self,
		                   forCellReuseIdentifier: "Cell")

	}

	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
//		self.tableView.reloadData()
		
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
	
	func tableView(_ tableView: UITableView,
	               numberOfRowsInSection section: Int) -> Int {
		return geoPoints.count
	}
	
	func tableView(_ tableView: UITableView,
	               cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		
		let geoPoint = geoPoints[indexPath.row]
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell",
		                                         for: indexPath)
		cell.textLabel?.text = geoPoint.value(forKeyPath: "geoPoint") as? String
		return cell
	}
}

