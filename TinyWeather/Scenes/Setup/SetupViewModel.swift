//
//  SetupViewModel.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//

import Foundation
import RxSwift
import CoreGraphics
import RxCocoa
import TWThemes
import TWRoutes
import TWModels

protocol SetupViewModelInputs {
    var viewDidLoad: PublishRelay<Void> { get }
}

protocol SetupViewModelOutputs {
    var launchImageName: Observable<String> { get }
}

protocol SetupViewModelProtocol {
    var theme: Theme { get }
    var inputs: SetupViewModelInputs { get }
    var outputs: SetupViewModelOutputs { get }
}

class SetupViewModel: SetupViewModelProtocol, SetupViewModelInputs, SetupViewModelOutputs {
    
    private let disposeBag: DisposeBag = DisposeBag()
    private let storage: StorageService
    private let router: WeakRouter<AppRoute>
    
    let theme: Theme

    var inputs: SetupViewModelInputs { return self }
    var outputs: SetupViewModelOutputs { return self }
    
    // Inputs
    let viewDidLoad: PublishRelay<Void> = PublishRelay()
    
    // Outputs
    let launchImageName: Observable<String>
    
    init(theme: Theme, router: WeakRouter<AppRoute>, storage: StorageService) {
        self.theme = theme
        self.storage = storage
        self.router = router
        
        self.launchImageName = Observable.just("LaunchImage")
        
        self.viewDidLoad
            .take(1)
            .subscribe(onNext: { [weak self] in
                self?.initialize()
            })
            .disposed(by: self.disposeBag)
    }
    
    //
    // MARK: - Private
    //
    
    private func initialize() {
        self.storage.initialize
            .subscribe(onCompleted: { [weak self] in
                self?.loadDefaultLocation()
            }, onError: { error in
                print(" Init error \(error)")
                // todo show alert
            })
            .disposed(by: self.disposeBag)
    }
    
    private func loadDefaultLocation() {
        self.storage.defaultLocation
            .observe(on: MainScheduler.instance)
            .subscribe(onSuccess: { [weak self] (location) in
                self?.router.route(to: .weather(location))
            }, onError: { [weak self] _ in
                // Ignore error, start with search
                self?.router.route(to: .search(nil))
            }, onCompleted: { [weak self] in
                // No default location, use the bundled one or route to the search
                if let location = self?.getDefaultLocation() {
                    self?.router.route(to: .weather(location))
                } else {
                    self?.router.route(to: .search(nil))
                }
            })
            .disposed(by: self.disposeBag)
    }
    
    private func getDefaultLocation() -> WeatherLocation? {
        if let path = Bundle.main.path(forResource: "Defaults", ofType: "plist"),
           let dict = NSDictionary(contentsOfFile: path),
           let name = dict.value(forKey: "TWDefaultLocationName") as? String,
           let country = dict.value(forKey: "TWDefaultLocationCountry") as? String,
           let latRaw = dict.value(forKey: "TWDefaultLocationLatitude") as? String,
           let lonRaw = dict.value(forKey: "TWDefaultLocationLongitude") as? String,
           let lat = Double(latRaw),
           let lon = Double(lonRaw) {
            let state = dict.value(forKey: "TWDefaultLocationState") as? String
            return Search.Location.Response(name: name, state: state, country: country, lon: lon, lat: lat)
        }
        return nil
    }

}
