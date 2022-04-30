//
//  UIViewController+Rx.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import TWModels
import UIKit

extension Reactive where Base: UIViewController {
    
    var alert: Binder<Alert.ViewModel> {
        return Binder(self.base) { vc, vm in
            let alert = UIAlertController(title: vm.title, message: vm.message, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: vm.button, style: .default, handler: nil))
            vc.present(alert, animated: true, completion: nil)
        }
    }
    
}
