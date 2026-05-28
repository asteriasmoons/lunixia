//
//  WeatherKitManager.swift
//  Lunixia
//

import Foundation
import WeatherKit
import CoreLocation

@Observable
@MainActor
final class WeatherKitManager: NSObject {
    static let shared = WeatherKitManager()

    private let service = WeatherService.shared
    private let locationManager = CLLocationManager()

    var weatherNote: String = ""
    var isLoading = false
    private var lastKnownLocation: CLLocation?

    private var locationContinuation: CheckedContinuation<CLLocation?, Never>?
    private var authorizationContinuation: CheckedContinuation<Bool, Never>?

    private override init() {
        super.init()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyKilometer
    }

    func fetchWeather() async {
        isLoading = true
        print("[WeatherKit] fetchWeather started")

        let location = await getLocation()

        guard let location else {
            print("[WeatherKit] no location available; clearing weatherNote")
            weatherNote = ""
            isLoading = false
            return
        }

        print("[WeatherKit] location ready: lat=\(location.coordinate.latitude), lon=\(location.coordinate.longitude)")

        do {
            let weather = try await WeatherService.shared.weather(for: location)
            let current = weather.currentWeather
            let condition = current.condition.description
            let tempF = current.temperature.converted(to: .fahrenheit).value
            let formatted = "\(condition), \(Int(tempF.rounded()))°F"

            print("[WeatherKit] weather loaded: \(formatted)")

            weatherNote = formatted
            isLoading = false
        } catch {
            print("[WeatherKit] WeatherKit error: \(error)")
            weatherNote = ""
            isLoading = false
        }
    }

    // MARK: - Location

    private func getLocation() async -> CLLocation? {
        if let loc = locationManager.location, loc.timestamp.timeIntervalSinceNow > -300 {
            print("[WeatherKit] using fresh CLLocationManager cached location")
            lastKnownLocation = loc
            return loc
        }

        if let loc = lastKnownLocation, loc.timestamp.timeIntervalSinceNow > -900 {
            print("[WeatherKit] using manager lastKnownLocation fallback")
            return loc
        }

        guard CLLocationManager.locationServicesEnabled() else {
            print("[WeatherKit] location services are disabled")
            return nil
        }

        let isAuthorized = await ensureLocationAuthorization()
        guard isAuthorized else {
            print("[WeatherKit] location authorization denied or unavailable")
            return nil
        }

        return await requestCurrentLocation()
    }

    private func ensureLocationAuthorization() async -> Bool {
        let status = locationManager.authorizationStatus
        print("[WeatherKit] authorization status: \(status.rawValue)")

        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            return true

        case .notDetermined:
            return await withCheckedContinuation { continuation in
                authorizationContinuation = continuation
                locationManager.requestWhenInUseAuthorization()
            }

        case .denied, .restricted:
            return false

        @unknown default:
            return false
        }
    }

    private func requestCurrentLocation() async -> CLLocation? {
        print("[WeatherKit] requesting current location")

        return await withTaskGroup(of: CLLocation?.self) { group in
            group.addTask { @MainActor in
                await self.waitForLocationUpdate()
            }

            group.addTask {
                try? await Task.sleep(nanoseconds: 8_000_000_000)
                return nil
            }

            let result = await group.next() ?? nil
            group.cancelAll()

            if result == nil {
                print("[WeatherKit] location request timed out")
                locationContinuation = nil
            }

            return result
        }
    }

    private func waitForLocationUpdate() async -> CLLocation? {
        await withCheckedContinuation { continuation in
            locationContinuation = continuation
            locationManager.requestLocation()
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension WeatherKitManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last ?? locations.first
        if let location {
            lastKnownLocation = location
            print("[WeatherKit] didUpdateLocations received location")
        } else {
            print("[WeatherKit] didUpdateLocations had no usable location")
        }

        locationContinuation?.resume(returning: location)
        locationContinuation = nil
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("[WeatherKit] location error: \(error)")
        locationContinuation?.resume(returning: nil)
        locationContinuation = nil
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        guard let continuation = authorizationContinuation else { return }

        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            continuation.resume(returning: true)
            authorizationContinuation = nil

        case .denied, .restricted:
            continuation.resume(returning: false)
            authorizationContinuation = nil

        case .notDetermined:
            break

        @unknown default:
            continuation.resume(returning: false)
            authorizationContinuation = nil
        }
    }
}
