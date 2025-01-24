//
//  ContentView.swift
//  pesawat Watch App
//
//  Created by moreno on 22/05/24.
//

import SwiftUI
import MapKit

struct ContentView: View {
    @State private var centerCoordinate = CLLocationCoordinate2D(latitude: -6.302481, longitude: 106.652323) // Initial coordinates
    @State private var zoomLevel: Double = 0.002 // Define a zoom level variable
    @State private var positionMap = MapCameraPosition.region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: -6.302481, longitude: 106.652323),
            span: MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        )
    )
    @State private var crownValue = 0.0
    @State private var isFocused = true
    @State private var score = 0
    @State private var annotations: [UUID: CLLocationCoordinate2D] = [:]
    @State private var enemies: [UUID: (coordinate: CLLocationCoordinate2D, spawnTime: Date)] = [:]
    @State private var gameOver = false
    @State private var gameActive = true

    // Timer that triggers every 0.01 second to move the map forward
    private let moveTimer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    // Timer that triggers every 3 seconds to add an annotation
    private let annotationTimer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()
    // Timer that triggers every 3 seconds to add an enemy
    private let enemyTimer = Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()

    // Maximum range for annotations and enemies from the center coordinate
    private let maxRange: Double = 0.1
    // Time in seconds after which enemies should disappear
    private let enemyLifetime: TimeInterval = 10.0

    var body: some View {
        ZStack {
            Map(position: $positionMap, interactionModes: .rotate) {
                ForEach(Array(annotations.keys), id: \.self) { id in
                    if let coordinate = annotations[id] {
                        Annotation("", coordinate: coordinate) {
                            ZStack {
                                Image("Xaphi")
                                    .resizable()
                                    .padding(5)
                                    .frame(width: 35, height: 30)
                            }
                        }
                    }
                }
                ForEach(Array(enemies.keys), id: \.self) { id in
                    if let (coordinate, _) = enemies[id] {
                        Annotation("", coordinate: coordinate) {
                            ZStack {
                                Image("EnemySaucer2")
                                    .resizable()
                                    .padding(5)
                                    .frame(width: 80, height: 80)
                            }
                        }
                    }
                }
            }
            .onChange(of: annotations) { _ in
                updateMapRegion()
            }
            .onChange(of: centerCoordinate) { _ in
                checkForCollisions()
                checkForEnemyCollisions()
            }
            .onMapCameraChange {
                updateMapRegion()
            }
            Image("PlayerSaucerHD")
                .resizable()
                .frame(width: 60, height: 60)
                .rotationEffect(.degrees(crownValue)) // Rotating the arrow based on crown value
            VStack {
                Text("Xaphis: \(score)")
                    .offset(y: -120)
                    .font(.footnote)
                if gameOver {
                    VStack{
                        Image("KroggSad")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                            .padding(.bottom, 20)
                        Button(action: restartGame) {
                            Text("Restart")
                                .font(.headline)
                                .padding()
                                .cornerRadius(10)
                        }
                        .padding()
                        .foregroundColor(.yellow)
                    }
                    .background(.black.opacity(0.5))
                }
            }
            Text("")
                .focusable()
                .digitalCrownRotation($crownValue)
        }
        .onReceive(moveTimer) { _ in
            if gameActive {
                moveCameraForward()
                moveEnemiesTowardCenter()
                removeOldEnemies()
            }
        }
        .onReceive(annotationTimer) { _ in
            if gameActive {
                addAnnotation()
            }
        }
        .onReceive(enemyTimer) { _ in
            if gameActive {
                addEnemy()
            }
        }
    }

    private func moveCameraForward() {
        // Convert the crown value to an angle in radians
        let headingInRadians = crownValue * .pi / 180 // Convert crown value to radians

        // Increase the movement speed based on the score
        let baseDistance: Double = 0.000003
        let speedMultiplier = 5.0 + Double(score) * 0.001
        let distance = baseDistance * speedMultiplier

        // Calculate the new position based on the current heading and crownValue
        centerCoordinate.latitude += distance * cos(headingInRadians)
        centerCoordinate.longitude += distance * sin(headingInRadians)

        // Update the position of the map
        updateMapRegion()
    }

    private func addAnnotation() {
        let randomOffset = 0.001
        let randomLatitude = centerCoordinate.latitude + (Double.random(in: -randomOffset...randomOffset))
        let randomLongitude = centerCoordinate.longitude + (Double.random(in: -randomOffset...randomOffset))
        let newCoordinate = CLLocationCoordinate2D(latitude: randomLatitude, longitude: randomLongitude)

        // Only add annotation if within max range
        if calculateDistance(from: centerCoordinate, to: newCoordinate) <= maxRange {
            annotations[UUID()] = newCoordinate
        }
    }

    private func addEnemy() {
        let spawnOffset = 0.007
        let randomLatitude = centerCoordinate.latitude + (Double.random(in: -spawnOffset...spawnOffset))
        let randomLongitude = centerCoordinate.longitude + (Double.random(in: -spawnOffset...spawnOffset))
        let newCoordinate = CLLocationCoordinate2D(latitude: randomLatitude, longitude: randomLongitude)

        // Only add enemy if within max range
        if calculateDistance(from: centerCoordinate, to: newCoordinate) <= maxRange {
            enemies[UUID()] = (newCoordinate, Date())
        }
    }

    private func moveEnemiesTowardCenter() {
        // Increase the movement speed based on the score
        let baseDistance: Double = 0.000004
        let speedMultiplier = 3.0 + Double(score) * 0.001
        let moveDistance = baseDistance * speedMultiplier

        enemies.keys.forEach { key in
            if var (coordinate, spawnTime) = enemies[key] {
                let latDelta = centerCoordinate.latitude - coordinate.latitude
                let lonDelta = centerCoordinate.longitude - coordinate.longitude
                let angle = atan2(latDelta, lonDelta)
                coordinate.latitude += moveDistance * sin(angle)
                coordinate.longitude += moveDistance * cos(angle)

                // Update enemy position
                enemies[key] = (coordinate, spawnTime)
            }
        }
    }

    private func removeOldEnemies() {
        let currentTime = Date()
        enemies.keys.forEach { key in
            if let (_, spawnTime) = enemies[key] {
                if currentTime.timeIntervalSince(spawnTime) > enemyLifetime {
                    enemies.removeValue(forKey: key)
                }
            }
        }
    }

    private func checkForCollisions() {
        let threshold: Double = 0.0003 // Distance threshold for collision detection

        annotations.keys.forEach { key in
            if let coordinate = annotations[key] {
                let distance = calculateDistance(from: centerCoordinate, to: coordinate)
                if distance <= threshold {
                    score += 1
                    annotations.removeValue(forKey: key)
                } else if distance > maxRange {
                    annotations.removeValue(forKey: key)
                }
            }
        }
    }

    private func checkForEnemyCollisions() {
        let threshold: Double = 0.0003 // Distance threshold for collision detection

        enemies.keys.forEach { key in
            if let (coordinate, _) = enemies[key] {
                let distance = calculateDistance(from: centerCoordinate, to: coordinate)
                if distance <= threshold {
                    gameOver = true
                    gameActive = false
                } else if distance > maxRange {
                    enemies.removeValue(forKey: key)
                }
            }
        }
    }

    private func restartGame() {
        // Reset game state
        centerCoordinate = CLLocationCoordinate2D(latitude: -6.302481, longitude: 106.652323)
        annotations.removeAll()
        enemies.removeAll()
        score = 0
        gameOver = false
        gameActive = true

        // Reset the map position
        updateMapRegion()
    }

    private func updateMapRegion() {
        positionMap = MapCameraPosition.region(
            MKCoordinateRegion(
                center: centerCoordinate,
                span: MKCoordinateSpan(latitudeDelta: zoomLevel, longitudeDelta: zoomLevel)
            )
        )
    }

    private func calculateDistance(from: CLLocationCoordinate2D, to: CLLocationCoordinate2D) -> Double {
        let latDelta = from.latitude - to.latitude
        let lonDelta = from.longitude - to.longitude
        return sqrt(latDelta * latDelta + lonDelta * lonDelta)
    }
}

extension CLLocationCoordinate2D: Equatable {
    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
}

#Preview {
    ContentView()
}
