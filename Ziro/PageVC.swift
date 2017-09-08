//
//  PageVC.swift
//  Ziro
//
//  Created by Eric on 7/14/17.
//  Copyright © 2017 Zixia. All rights reserved.
//

import UIKit

class PageVC: UIPageViewController, UIPageViewControllerDataSource,UIPageViewControllerDelegate {
	var resultSearchController:UISearchController!
	var pageControl : UIPageControl = UIPageControl()
	var currentIndex: Int?
	private var pendingIndex: Int?
	lazy var VCArr:[UIViewController] = {
		return [self.VCInstance(name:"MapVCNav"),self.VCInstance(name:"InfoVCNav")]
	}()
	
	private func VCInstance(name:String) -> UIViewController{
		return UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier:name)
	}
	override func viewDidLoad() {
		super.viewDidLoad()
		self.dataSource = self
		self.delegate = self
		self.view.backgroundColor = UIColor.white
		if let firstVC = VCArr.first {
			setViewControllers([firstVC], direction: .forward, animated: true, completion: nil)
		}
		
		pageControl.pageIndicatorTintColor = UIColor.gray
		pageControl.currentPageIndicatorTintColor = UIColor.lightGray
		pageControl.backgroundColor = UIColor.darkGray
		pageControl.numberOfPages = 2
		pageControl.center = self.view.center
		view.bringSubview(toFront: pageControl)
		pageControl.currentPage = 0
		pageControl.layer.position.y = self.view.frame.height - 70;
		//		self.view.addSubview(pageControl)

	}
	
	public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController?{
		guard let viewControllerIndex = VCArr.index(of: viewController) else {
			return nil
		}
		let previousIndex = viewControllerIndex - 1
		
		guard previousIndex >= 0 else {
			return nil
		}
		
		guard VCArr.count > previousIndex else{
			return nil
		}
		
		return VCArr[previousIndex]
	}
	
	public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController?{
		guard let viewControllerIndex = VCArr.index(of: viewController) else {
			return nil
		}
		let nextIndex = viewControllerIndex + 1
		
		guard nextIndex < VCArr.count else {
			return nil
		}
		
		guard VCArr.count > nextIndex else{
			return nil
		}
		
		return VCArr[nextIndex]

	}
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		for view in self.view.subviews{
			if view is UIScrollView{
				view.frame = UIScreen.main.bounds
			}else if view is UIPageControl{
				view.backgroundColor = UIColor.clear 
			}
		}
	}
	
	public func presentationCount(for pageViewController: UIPageViewController) -> Int{
		return VCArr.count
	}
	
	public func presentationIndex(for pageViewController: UIPageViewController) -> Int {
		guard let firstViewController = viewControllers?.first,
			let firstViewControllerIndex = VCArr.index(of: firstViewController) else{
				return 0
		}
		self.pageControl.currentPage = firstViewControllerIndex
		return firstViewControllerIndex
	
	}
	
	public func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]){
		pendingIndex = VCArr.index(of: pendingViewControllers.first!)
	}
	
	public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool){
		if completed {
			currentIndex = pendingIndex
			if let index = currentIndex {
				pageControl.currentPage = index
			}
		}
	}
}
