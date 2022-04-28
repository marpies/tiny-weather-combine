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
import CoreGraphics
import TWThemes
import TWRoutes
import TWModels
import Combine

protocol SetupViewModelInputs {
    var viewDidLoad: PassthroughSubject<Void, Never> { get }
}

protocol SetupViewModelOutputs {
    var launchImageName: AnyPublisher<String, Never> { get }
}

protocol SetupViewModelProtocol {
    var theme: Theme { get }
    var inputs: SetupViewModelInputs { get }
    var outputs: SetupViewModelOutputs { get }
}

class SetupViewModel: SetupViewModelProtocol, SetupViewModelInputs, SetupViewModelOutputs {
    
    private var cancellables: Set<AnyCancellable> = []
    
    private let storage: StorageService
    private let router: WeakRouter<AppRoute>
    
    let theme: Theme

    var inputs: SetupViewModelInputs { return self }
    var outputs: SetupViewModelOutputs { return self }
    
    // Inputs
    let viewDidLoad: PassthroughSubject<Void, Never> = PassthroughSubject()
    
    // Outputs
    let launchImageName: AnyPublisher<String, Never>
    
    init(theme: Theme, router: WeakRouter<AppRoute>, storage: StorageService) {
        self.theme = theme
        self.storage = storage
        self.router = router
        
        self.launchImageName = Just("LaunchImage").eraseToAnyPublisher()
        
        self.viewDidLoad
            .prefix(1)
            .sink { [weak self] _ in
                self?.initialize()
            }
            .store(in: &self.cancellables)
    }
    
    //
    // MARK: - Private
    //
    
    private func initialize() {
        self.storage.initialize
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    print(" Init error \(error)")
                    // todo show alert
                    
                default:
                    break
                }
            }, receiveValue: { [weak self] in
                self?.loadDefaultLocation()
            })
            .store(in: &self.cancellables)
    }
    
    private func loadDefaultLocation() {
        self.storage.defaultLocation
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] (completion) in
                if case .failure = completion {
                    // Ignore error, start with search
                    self?.router.route(to: .search(nil))
                }
            }, receiveValue: { [weak self] (location) in
                let loc: WeatherLocation? = location ?? self?.getDefaultLocation()
                if let l = loc {
                    self?.router.route(to: .weather(l))
                } else {
                    self?.router.route(to: .search(nil))
                }
            })
            .store(in: &self.cancellables)
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
