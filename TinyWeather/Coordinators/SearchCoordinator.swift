//
//  SearchCoordinator.swift
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
import Combine
import TWRoutes
import TWModels

class SearchCoordinator: Coordinator {
    
    private let resolver: Resolver
    private var viewController: SearchViewController?
    
    private var cancellables: Set<AnyCancellable> = []
    private let router: WeakRouter<AppRoute>
    
    // Outputs
    private let _sceneDidHide: PassthroughSubject<Void, Never> = PassthroughSubject()
    let sceneDidHide: AnyPublisher<Void, Never>
    
    private let _favoriteDidDelete: PassthroughSubject<WeatherLocation, Never> = PassthroughSubject()
    let favoriteDidDelete: AnyPublisher<WeatherLocation, Never>
    
    /// Set to `true` before starting the coordinator to allow for interactive pan animation.
    var interactiveAnimation: Bool = false
    
    weak var parent: Coordinator?
    var children: [Coordinator] = []
    let navigationController: UINavigationController

    init(navigationController: UINavigationController, router: WeakRouter<AppRoute>, resolver: Resolver) {
        self.navigationController = navigationController
        self.router = router
        self.resolver = resolver
        self.sceneDidHide = _sceneDidHide.eraseToAnyPublisher()
        self.favoriteDidDelete = _favoriteDidDelete.eraseToAnyPublisher()
    }
    
    @discardableResult func start() -> UIViewController {
        let vm: SearchViewModelProtocol = self.resolver.resolve(SearchViewModelProtocol.self, arguments: self.router, self.interactiveAnimation)!
        self.viewController = self.resolver.resolve(SearchViewController.self, argument: vm)
        
        vm.outputs.sceneDidHide
            .assign(to: self._sceneDidHide)
            .store(in: &self.cancellables)
        
        vm.outputs.favoriteDidDelete
            .assign(to: self._favoriteDidDelete)
            .store(in: &self.cancellables)
        
        if let root = self.navigationController.topViewController, let vc = self.viewController {
            root.addChild(vc)
            vc.view.frame = root.view.frame
            root.view.addSubview(vc.view)
            vc.didMove(toParent: root)
        }
        
        return self.viewController!
    }
    
    func animateIn() {
        self.viewController?.animateIn()
    }
    
    func animateOut() {
        self.viewController?.animateOut()
    }
    
    func dispose() {
        if self.viewController?.parent != nil {
            self.viewController?.willMove(toParent: nil)
            self.viewController?.view.removeFromSuperview()
            self.viewController?.removeFromParent()
        }
    }
    
    func animate(_ animation: RoutePanAnimation) {
        switch animation {
        case .began:
            self.viewController?.startScrubbingAnimation()
            
        case .changed(let translation):
            self.viewController?.updateAnimationProgress(translation: translation)
            break
            
        case .ended(let velocity):
            self.viewController?.finishAnimation(velocity: velocity)
            break
        }
    }
    
}
