//
//  SettingVC.swift
//  Ziro
//
//  Created by Eric on 10/26/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import Foundation
import UIKit
import Photos

class SettingVC: UITableViewController, UIImagePickerControllerDelegate,UINavigationControllerDelegate {
	@IBOutlet weak var userImageView: UIImageView!
	let myPickerController = UIImagePickerController()
	override func viewDidLoad() {
		super.viewDidLoad()
		checkPermission()
		let singleTap = UITapGestureRecognizer(target: self, action: #selector(SettingTableViewController.userImageTapDetected))
		singleTap.numberOfTapsRequired = 1 // you can change this value
		userImageView.isUserInteractionEnabled = true
		userImageView.addGestureRecognizer(singleTap)
		myPickerController.delegate = self
		// Uncomment the following line to preserve selection between presentations
		// self.clearsSelectionOnViewWillAppear = false
		
		// Uncomment the following line to display an Edit button in the navigation bar for this view controller.
		// self.navigationItem.rightBarButtonItem = self.editButtonItem
	}
	
	func userImageTapDetected() {
		print("userImageTapDetected")
		myPickerController.allowsEditing = false
		myPickerController.delegate = self as UIImagePickerControllerDelegate & UINavigationControllerDelegate
		myPickerController.sourceType = UIImagePickerControllerSourceType.photoLibrary
		
		self.present(myPickerController, animated: true, completion: nil)
		
	}
	private func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject])
		
	{
		print("hellp")
		if let pickedImage = info[UIImagePickerControllerOriginalImage] as? UIImage {
			userImageView.contentMode = .scaleAspectFit
			userImageView.image = pickedImage
		}
		self.dismiss(animated: true, completion: nil)
		
	}
	
	func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
		dismiss(animated: true, completion: nil)
	}

	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	// MARK: - Table view data source
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		// #warning Incomplete implementation, return the number of sections
		return 2
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		// #warning Incomplete implementation, return the number of rows
		if (section == 0){
			return 1
		}
		else{
			return 2
		}
	}
	func checkPermission() {
		let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
		switch photoAuthorizationStatus {
		case .authorized:
			print("Access is granted by user")
		case .notDetermined:
			PHPhotoLibrary.requestAuthorization({
				(newStatus) in
				print("status is \(newStatus)")
				if newStatus ==  PHAuthorizationStatus.authorized {
					/* do stuff here */
					print("success")
				}
			})
			print("It is not determined until now")
		case .restricted:
			// same same
			print("User do not have access to photo album.")
		case .denied:
			// same same
			print("User has denied the permission.")
		}
	}
}

