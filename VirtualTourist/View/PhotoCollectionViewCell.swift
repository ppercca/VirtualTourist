//
//  PhotoCollectionCellView.swift
//  VirtualTourist
//
//  Created by Paul Cristian Percca Julca on 7/25/20.
//  Copyright © 2020 Innovatrix. All rights reserved.
//

import Foundation
import UIKit
class PhotoCollectionViewCell: UICollectionViewCell {

    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var highlightIndicator: UIView!
    @IBOutlet weak var selectIndicator: UIImageView!
    
    override var isHighlighted: Bool {
      didSet {
        highlightIndicator.isHidden = !isHighlighted
      }
    }
    
    override var isSelected: Bool {
      didSet {
        highlightIndicator.isHidden = !isSelected
        selectIndicator.isHidden = !isSelected
      }
    }
}
