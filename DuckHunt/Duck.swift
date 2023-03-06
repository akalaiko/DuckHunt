//
//  Duck.swift
//  DuckHunt
//
//  Created by Tim on 09.12.2022.
//

import Foundation
import SpriteKit

protocol FlyingAway {
    var isFlyingAway: Bool { get set }
}

final class Duck: SKSpriteNode, FlyingAway {
    var isFlyingAway = false
}
