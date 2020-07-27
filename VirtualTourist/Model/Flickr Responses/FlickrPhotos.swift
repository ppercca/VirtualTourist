//
//  FlickrPhotos.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/23/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation

struct FlickrPhotos: Codable {
    let page: Int
    let pages: Int
    let perpage: Int
    let total: String
    let photo: [FlickrPhoto]
}
