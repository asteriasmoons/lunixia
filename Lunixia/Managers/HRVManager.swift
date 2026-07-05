import Foundation
import HealthKit
import SwiftData
import WidgetKit

class HRVManager {
    static let shared = HRVManager()
    
    private let store = HKHealthStore()
    
    private init() {}
    
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        do {
            try await store.requestAuthorization(toShare: [], read: [hrvType]) 
        } catch {
            print("HRV HealthKit auth error: \(error)")
        }
    }
    
    func fetchLatestHRV() async -> Double {
        guard let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { 
            return 0
        }
        
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        
        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
                guard let sample = samples?.first as? HKQuantitySample else {
                    continuation.resume(returning: 0)
                    return
                }
                
                let unit = HKUnit.secondUnit(with: .milli) 
                let value = sample.quantity.doubleValue(for: unit)
                continuation.resume(returning: value)
            }
            
            store.execute(query) 
        }
    }
}
