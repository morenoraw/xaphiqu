//
//  File.swift
//  pesawat Watch App
//
//  Created by moreno on 22/05/24.
//

import SwiftUI
import MapKit
import CoreLocation

struct Plane: Identifiable {
    let id = UUID()
    var coordinate: CLLocationCoordinate2D
}
