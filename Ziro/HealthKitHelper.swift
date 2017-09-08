//
//  HealthKitHelper.swift
//  Ziro
//
//  Created by Eric on 8/3/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import Foundation
import UIKit
import HealthKit

class HealthKitManager {
	class var sharedInstance: HealthKitManager {
		struct Singleton {
			static let instance = HealthKitManager()
		}
		
		return Singleton.instance
	}
	
	let healthStore: HKHealthStore? = {
		if HKHealthStore.isHealthDataAvailable() {
			return HKHealthStore()
		} else {
			return nil
		}
	}()
	
	let stepsCount = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.stepCount)
	
	let stepsUnit = HKUnit.count()	
}
