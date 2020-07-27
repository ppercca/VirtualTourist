//
//  FlickrClient.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/22/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation
import UIKit

class FlickrClient {
    
    static let apiKey = "f7e684ab9481b394e2478f61380abcf7"
    
    struct Constants {
         static var accountKey = ""
         static var firstName = ""
         static var lastName = ""
         static var objectId = ""
     }
    
    enum Endpoints {
        static let base = "https://www.flickr.com/services/rest/"
        static let apiKeyParam = "&api_key=\(FlickrClient.apiKey)"
        static let perPageParam = "&per_page=25"
        
        case getPhotos(Double, Double, Int)
        case getPhotoImage(Int, String, String, String)
         
        var stringValue: String {
            switch self {
            case .getPhotos(let latitude,let longitude, let page):
                return Endpoints.base + "?method=flickr.photos.search" + Endpoints.apiKeyParam + "&lat=\(latitude)&lon=\(longitude)" + Endpoints.perPageParam + "&page=\(page)&format=json&nojsoncallback=1"
            case .getPhotoImage(let farmId, let serverId, let id, let secret):
                return "https://farm\(farmId).staticflickr.com/\(serverId)/\(id)_\(secret).jpg"
             }
         }
         
         var url: URL {
             return URL(string: stringValue)!
         }
     }
    
    class func getPhotos(latitude: Double, longitude: Double, page: Int, completion: @escaping (FlickrPhotosResponse?, Error?) -> Void) {
        let url = Endpoints.getPhotos(latitude, longitude, page).url
        print(url.absoluteString)
        taskForGETRequest(url: url, responseType: FlickrPhotosResponse.self) { (response, error) in
            if let response = response {
                completion(response, nil)
            } else {
                completion(nil, error)
            }
        }
    }
    
    class func requestImageFile(url: URL, completionHandler: @escaping (UIImage?, Error?) -> Void) {
        let task = URLSession.shared.dataTask(with: url, completionHandler: { (data, response, error) in
            guard let data = data else {
                completionHandler(nil, error)
                return
            }
            let downloadImage = UIImage(data: data)
            completionHandler(downloadImage, nil)
        })
        task.resume()
    }
    
    // MARK: - Http Methods
    
    @discardableResult class func taskForGETRequest<ResponseType: Decodable>(url: URL, responseType: ResponseType.Type, completion: @escaping (ResponseType?, Error?) -> Void) -> URLSessionTask {
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
                return
            }
            let decoder = JSONDecoder()
            do {
//                print(NSString(data: data, encoding: String.Encoding.utf8.rawValue) ?? "")
                let responseObject = try decoder.decode(responseType.self, from: data)
                DispatchQueue.main.async {
                    completion(responseObject, nil)
                }
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error)
                }
            }
        }
        task.resume()
        return task
    }
}
