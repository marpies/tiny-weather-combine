//
//  TestExtensions.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation
import XCTest
import Combine

extension Dictionary where Key == String, Value == Any {
    
    var asData: Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
    func double(_ key: String) -> Double {
        return (self[key] as? Double) ?? 0
    }
    
    func int(_ key: String) -> Int {
        return (self[key] as? Int) ?? 0
    }
    
    func string(_ key: String) -> String {
        return self.stringOptional(key) ?? ""
    }
    
    func stringOptional(_ key: String) -> String? {
        return self[key] as? String
    }
    
}

extension Array where Element == [String: Any] {
    
    var asData: Data {
        return try! JSONSerialization.data(withJSONObject: self, options: [])
    }
    
}

extension XCTestCase {
    
    /// https://www.swiftbysundell.com/articles/unit-testing-combine-based-swift-code/
    func awaitPublisher<T: Publisher>(
        _ publisher: T,
        timeout: TimeInterval = 0.5,
        file: StaticString = #file,
        line: UInt = #line
    ) throws -> Result<T.Output, Error> {
        var result: Result<T.Output, Error>?
        let expectation = self.expectation(description: "Awaiting publisher")
        
        let cancellable = publisher.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure(let error):
                    result = .failure(error)
                case .finished:
                    break
                }
                
                expectation.fulfill()
            },
            receiveValue: { value in
                result = .success(value)
            }
        )
        
        waitForExpectations(timeout: timeout)
        
        cancellable.cancel()
        
        let unwrappedResult = try XCTUnwrap(
            result,
            "Awaited publisher did not produce any output",
            file: file,
            line: line
        )
        
        return unwrappedResult
    }
    
}
