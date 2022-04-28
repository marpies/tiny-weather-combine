//
//  Response+CurrentAndDaily.swift
//  TinyWeather
//
//  Created by Marcel Piešťanský.
//  Copyright © 2022 Marcel Piestansky. All rights reserved.
//  
//  This program is free software. You can redistribute and/or modify it in
//  accordance with the terms of the accompanying license agreement.
//  

import Foundation

enum ResponseCurrentAndDaily {
    static func getSuccessResponse(timestamp: TimeInterval) -> [String: Any] {
        return [
            "lat": -33.7685,
            "lon": 150.9569,
            "timezone": "Australia/Sydney",
            "timezone_offset": 36000,
            "current":
                [
                    "dt": timestamp,
                    "sunrise": 1649189483,
                    "sunset": 1649231143,
                    "temp": 17.04,
                    "wind_speed": 1.18,
                    "weather":
                        [
                            [
                                "id": 804,
                                "main": "Clouds",
                                "description": "overcast clouds",
                                "icon": "04n"
                            ]
                        ]
                ],
            "daily":
                [
                    [
                        "dt": 1649206800,
                        "sunrise": 1649189483,
                        "sunset": 1649231143,
                        "temp":
                            [
                                "min": 16.45,
                                "max": 18.38
                            ],
                        "wind_speed": 4.08,
                        "weather":
                            [
                                [
                                    "id": 501,
                                    "main": "Rain",
                                    "description": "moderate rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 17.49
                    ],
                    [
                        "dt": 1649293200,
                        "sunrise": 1649275927,
                        "sunset": 1649317464,
                        "temp":
                            [
                                "min": 16.08,
                                "max": 17.34,
                            ],
                        "wind_speed": 4.72,
                        "weather":
                            [
                                [
                                    "id": 502,
                                    "main": "Rain",
                                    "description": "heavy intensity rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 105.61
                    ],
                    [
                        "dt": 1649379600,
                        "sunrise": 1649362371,
                        "sunset": 1649403786,
                        "temp":
                            [
                                "min": 16.68,
                                "max": 19.26
                            ],
                        "wind_speed": 4.2,
                        "weather":
                            [
                                [
                                    "id": 501,
                                    "main": "Rain",
                                    "description": "moderate rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 14.84
                    ],
                    [
                        "dt": 1649466000,
                        "sunrise": 1649448815,
                        "sunset": 1649490108,
                        "temp":
                            [
                                "min": 16.51,
                                "max": 21.02,
                            ],
                        "wind_speed": 2.91,
                        "weather":
                            [
                                [
                                    "id": 501,
                                    "main": "Rain",
                                    "description": "moderate rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 16.52
                    ],
                    [
                        "dt": 1649552400,
                        "sunrise": 1649535259,
                        "sunset": 1649576431,
                        "temp":
                            [
                                "min": 16.65,
                                "max": 23.53,
                            ],
                        "wind_speed": 1.84,
                        "weather":
                            [
                                [
                                    "id": 500,
                                    "main": "Rain",
                                    "description": "light rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 2.69
                    ],
                    [
                        "dt": 1649638800,
                        "sunrise": 1649621703,
                        "sunset": 1649662754,
                        "temp":
                            [
                                "min": 16.07,
                                "max": 24.54
                            ],
                        "wind_speed": 3.99,
                        "weather":
                            [
                                [
                                    "id": 500,
                                    "main": "Rain",
                                    "description": "light rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 0.78
                    ],
                    [
                        "dt": 1649725200,
                        "sunrise": 1649708147,
                        "sunset": 1649749078,
                        "temp":
                            [
                                "min": 16.78,
                                "max": 24.29
                            ],
                        "wind_speed": 2.41,
                        "weather":
                            [
                                [
                                    "id": 804,
                                    "main": "Clouds",
                                    "description": "overcast clouds",
                                    "icon": "04d"
                                ]
                            ]
                    ],
                    [
                        "dt": 1649811600,
                        "sunrise": 1649794592,
                        "sunset": 1649835402,
                        "temp":
                            [
                                "min": 16.97,
                                "max": 27.02
                            ],
                        "wind_speed": 3.58,
                        "weather":
                            [
                                [
                                    "id": 500,
                                    "main": "Rain",
                                    "description": "light rain",
                                    "icon": "10d"
                                ]
                            ],
                        "rain": 2.92
                    ]
                ]
        ]
    }
}
