//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/23/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation
struct FlickrPhotosResponse: Codable {
    let photos: FlickrPhotos
    let stat: String
}
