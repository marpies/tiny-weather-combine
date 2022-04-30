//
//  WeatherCoordinator.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import UIKit
import Swinject
import TWRoutes
import TWModels

class WeatherCoordinator: Coordinator {
    
    private let resolver: Resolver
    private let viewController: WeatherViewController
    private let viewModel: WeatherViewModelProtocol
    
    private let router: WeakRouter<AppRoute>
    
    weak var parent: Coordinator?
    var children: [Coordinator] = []
    let navigationController: UINavigationController
    
    init(navigationController: UINavigationController, router: WeakRouter<AppRoute>, resolver: Resolver) {
        self.navigationController = navigationController
        self.router = router
        self.resolver = resolver
        
        self.viewModel = self.resolver.resolve(WeatherViewModelProtocol.self, argument: router)!
        self.viewController = self.resolver.resolve(WeatherViewController.self, argument: self.viewModel)!
    }
    
    @discardableResult func start() -> UIViewController {
        self.navigationController.setViewControllers([self.viewController], animated: true)
        
        return self.viewController
    }
    
    func displayWeather(forLocation location: WeatherLocation) {
        self.viewModel.loadWeather(forLocation: location)
    }
    
    func favoriteDidDelete(forLocation location: WeatherLocation) {
        self.viewModel.favoriteDidDelete(forLocation: location)
    }
    
}
