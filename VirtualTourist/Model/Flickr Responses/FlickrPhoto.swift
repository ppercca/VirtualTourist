//
//  FlickrPhoto.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/23/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation
struct FlickrPhoto: Codable {
    let id: String
    let owner: String
    let secret: String
    let server: String
    let farm: Int
    let title: String
    let ispublic: Int
    let isfriend: Int
    let isfamily: Int
}
