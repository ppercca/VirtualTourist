//
//  PhotosResponse.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/23/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation
struct FlickrPhotosResponse: Codable {
    let photos: Photos
    let stat: String
    
    enum CodingKeys: String, CodingKey {
        case statusCode = "status_code"
        case statusMessage = "status_message"
    }
}
