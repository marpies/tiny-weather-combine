//
//  AppDelegate.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

import UIKit
import Swinject

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UINavigationControllerDelegate {
    
    private var coordinator: Coordinator?
    private var assembler: Assembler?

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        self.assembler = Assembler()
        self.coordinator = AppCoordinator(assembler: self.assembler!)
        
        guard let navigationController = self.coordinator?.start() as? UINavigationController else {
            assertionFailure("Expected UINavigationController")
            return false
        }
        
        navigationController.delegate = self
        
        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.backgroundColor = .black
        self.window?.rootViewController = navigationController
        self.window?.makeKeyAndVisible()
        
        return true
    }
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        switch operation {
        case .push:
            return TransitionAnimator(pushing: true)
        case .pop:
            return TransitionAnimator(pushing: false)
        default:
            return nil
        }
    }

}

