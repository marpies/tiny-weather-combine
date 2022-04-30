//
//  ReactiveLocationManager.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import CoreLocation
import Combine

class ReactiveLocationManager: NSObject, LocationManager, CLLocationManagerDelegate {
    
    private let locationManager: CLLocationManager = CLLocationManager()
    
    private let authorizationStatus: PassthroughSubject<CLAuthorizationStatus, Never> = PassthroughSubject()
    private let locations: PassthroughSubject<[CLLocation], Never> = PassthroughSubject()
    
    var currentLocation: AnyPublisher<CLLocation, Never> {
        let publisher = self.authorizationStatus
            .prepend(self.locationManager.currentAuthenticationStatus)
            .filter({ $0 == .authorizedWhenInUse || $0 == .authorizedAlways })
            .flatMap({ [locations] _ in
                locations.compactMap(\.first)
            })
            .prefix(1)
            .handleEvents(receiveCompletion: { [weak self] _ in
                self?.locationManager.stopUpdatingLocation()
            })
            .eraseToAnyPublisher()
        
        self.locationManager.requestWhenInUseAuthorization()
        self.locationManager.startUpdatingLocation()
        
        return publisher
    }
    
    override init() {
        super.init()
        
        self.locationManager.delegate = self
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        self.authorizationStatus.send(status)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        self.locations.send(locations)
    }
    
}


fileprivate extension CLLocationManager {
    
    var currentAuthenticationStatus: CLAuthorizationStatus {
        if #available(iOS 14.0, *) {
            return self.authorizationStatus
        }
        return CLLocationManager.authorizationStatus()
    }
    
}
