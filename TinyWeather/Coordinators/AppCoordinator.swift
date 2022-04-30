//
//  AppCoordinator.swift
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
import RxSwift
import TWRoutes
import TWModels

class AppCoordinator: Coordinator, Router {
    
    private let resolver: Resolver
    
    private let disposeBag: DisposeBag = DisposeBag()
    
    let navigationController: UINavigationController
    var parent: Coordinator?
    var children: [Coordinator] = []
    
    var weakRouter: WeakRouter<AppRoute> {
        return WeakRouter(self)
    }

    init(assembler: Assembler) {
        self.resolver = assembler.resolver
        self.navigationController = UINavigationController()
        self.setupAssembler(assembler)
    }
    
    @discardableResult func start() -> UIViewController {
        self.route(to: .setup)
        
        self.navigationController.setNavigationBarHidden(true, animated: false)
        
        return self.navigationController
    }
    
    func route(to route: AppRoute) {
        switch route {
        case .setup:
            self.routeToSetup()
        case .search(let animation):
            self.routeToSearch(animation: animation)
        case .weather(let location):
            self.routeToWeather(forLocation: location)
        }
    }
    
    //
    // MARK: - Private
    //
    
    private func routeToSetup() {
        let vm: SetupViewModelProtocol = self.resolver.resolve(SetupViewModelProtocol.self, argument: self.weakRouter)!
        let vc: SetupViewController = self.resolver.resolve(SetupViewController.self, argument: vm)!
        
        self.navigationController.setViewControllers([vc], animated: false)
    }
    
    private func routeToSearch(animation: RoutePanAnimation?) {
        let coordinator: SearchCoordinator
        
        if let coord = self.children.first(where: { $0 is SearchCoordinator }) as? SearchCoordinator {
            coordinator = coord
        } else {
            coordinator = SearchCoordinator(navigationController: self.navigationController, router: self.weakRouter, resolver: self.resolver)
            coordinator.parent = self
            coordinator.interactiveAnimation = animation != nil
            self.children.append(coordinator)
            
            // Propagate deleted favorite location to the weather scene
            coordinator.favoriteDidDelete
                .subscribe(onNext: { [weak self] (location) in
                    self?.deleteFavoriteInWeatherScene(location: location)
                })
                .disposed(by: self.disposeBag)
            
            // Dispose the scene when it is hidden
            coordinator.sceneDidHide
                .take(1)
                .subscribe(onNext: { [weak self] in
                    self?.childDidComplete(coordinator)
                    coordinator.dispose()
                })
                .disposed(by: self.disposeBag)
            
            coordinator.start()
        }
        
        if let animation = animation {
            coordinator.animate(animation)
        } else {
            coordinator.animateIn()
        }
    }
    
    private func routeToWeather(forLocation location: WeatherLocation) {
        let coordinator: WeatherCoordinator
        
        if let coord = self.children.first(where: { $0 is WeatherCoordinator }) as? WeatherCoordinator {
            coordinator = coord
            
            // Hide search if needed
            if let searchCoord = self.children.first(where: { $0 is SearchCoordinator }) as? SearchCoordinator {
                searchCoord.animateOut()
            }
        } else {
            coordinator = WeatherCoordinator(navigationController: self.navigationController, router: self.weakRouter, resolver: self.resolver)
            coordinator.parent = self
            self.children.append(coordinator)
            
            coordinator.start()
        }
        
        coordinator.displayWeather(forLocation: location)
    }
    
    private func deleteFavoriteInWeatherScene(location: WeatherLocation) {
        if let coord = self.children.first(where: { $0 is WeatherCoordinator }) as? WeatherCoordinator {
            coord.favoriteDidDelete(forLocation: location)
        }
    }
    
    private func setupAssembler(_ assembler: Assembler) {
        assembler.apply(assemblies: [
            ThemeAssembly(),
            SetupAssembly(),
            SearchAssembly(),
            WeatherAssembly(),
            NetworkingAssembly(),
            CoreDataAssembly(),
            ServicesAssembly()
        ])
    }
    
}
