//
//  DescribeImage.swift
//  Kate Assignment 3 App
//
//  Created by user919256 on 11/13/19.
//  Copyright © 2019 user919256. All rights reserved.
//

import Foundation

struct DescribeImage: Codable {
    let description: Description?
    let requestId: String?
}

struct Description: Codable {
    let tags: [String]?
    let captions: [Caption]?
}

struct Caption: Codable {
    let text: String?
    let confidence: Float?
}
