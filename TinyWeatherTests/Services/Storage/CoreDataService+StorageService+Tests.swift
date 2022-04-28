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
import Combine
@testable import TinyWeather

class CoreDataService_StorageService_Tests: XCTestCase {
    
    private var sut: StorageService!
    private var cancellables: Set<AnyCancellable>!

    override func setUpWithError() throws {
        let store = CoreDataStore(inMemory: true)
        self.sut = CoreDataService(store: store)
        self.cancellables = []
    }

    override func tearDownWithError() throws {
        self.sut = nil
        self.cancellables.removeAll()
    }

    func testInitialize() throws {
        let expect = expectation(description: #function)
        
        self.sut.initialize
            .sink(receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    XCTFail(error.localizedDescription)
                    
                case .finished:
                    expect.fulfill()
                }
            }, receiveValue: { })
            .store(in: &self.cancellables)
        
        waitForExpectations(timeout: 1) { error in
            if let e = error {
                XCTFail(e.localizedDescription)
            }
        }
    }

}
