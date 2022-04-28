//
//  CoreDataService+StorageService+Tests.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import XCTest
import RxSwift
@testable import TinyWeather

class CoreDataService_StorageService_Tests: XCTestCase {
    
    private var sut: StorageService!

    override func setUpWithError() throws {
        let store = CoreDataStore(inMemory: true)
        self.sut = CoreDataService(store: store)
    }

    override func tearDownWithError() throws {
        self.sut = nil
    }

    func testInitialize() throws {
        let initialize = self.sut.initialize.toBlocking(timeout: 1).materialize()
        
        switch initialize {
        case .completed(_):
            break
        case .failed(_, let error):
            XCTFail(error.localizedDescription)
        }
    }

}
