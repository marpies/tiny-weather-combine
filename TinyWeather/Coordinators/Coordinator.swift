//
//  Coordinator.swift
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

protocol Coordinator: AnyObject {
    var parent: Coordinator? { get set }
    var children: [Coordinator] { get set }
    var navigationController: UINavigationController { get }
    
    @discardableResult func start() -> UIViewController
}

extension Coordinator {
    func childDidComplete(_ child: Coordinator) {
        if let index = self.children.firstIndex(where: { $0 === child }) {
            self.children.remove(at: index)
        }
    }
}
