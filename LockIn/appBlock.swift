//
//  ActivityMonitor.swift
//  LMNT
//
//  Created by Matthew Lu on 6/3/25.
//
import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity


func blockApps(selection: FamilyActivitySelection, timeSet : Int) {
//    guard !tokens.isEmpty else {
//        print("No tokens provided")
//        return
//    }

    //double check authorization
    let authStatus = AuthorizationCenter.shared.authorizationStatus
    print("Authorization status: \(authStatus)")

    guard authStatus == .approved else {
        print("Screen Time authorization not granted")
        return
    }

    let store = ManagedSettingsStore()

    //blocker for individual apps
    if !selection.applicationTokens.isEmpty {
        print("Blocking \(selection.applicationTokens.count) individual apps")
        store.shield.applications = selection.applicationTokens
    }

    //blocker for categories
    if !selection.categoryTokens.isEmpty {
        print("Blocking \(selection.categoryTokens.count) categories")
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    //blocker for websites
    if !selection.webDomainTokens.isEmpty {
        print("Blocking \(selection.webDomainTokens.count) web domains")
        store.shield.webDomains = selection.webDomainTokens
    }

    guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
        print("No tokens provided in selection")
        return
    }

    let now = Date()
    let cal = Calendar.current
    let start = cal.dateComponents([.hour, .minute, .second], from: now)
    guard let endDate = cal.date(byAdding: .minute, value: timeSet, to: now) else {
        print("Failed to create end date")
        return
    }

    let end = cal.dateComponents([.hour, .minute, .second], from: endDate)

    let schedule = DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: false)
    let name = DeviceActivityName("LMNT_Block")
    let center = DeviceActivityCenter()
    center.stopMonitoring([name])

    print("Schedule: \(start) to \(end)")

    do {
        try center.startMonitoring(name, during: schedule, events: [:])
    } catch {
        print("Failed to start monitoring: \(error)")
        if let deviceActivityError = error as? DeviceActivityCenter.MonitoringError {
            switch deviceActivityError {
            case .excessiveActivities:
                print("Too many activities running")
            case .unauthorized:
                print("Unauthorized")
            default:
                print("Unknown DeviceActivity error")
            }
        }
    }
}

func blockAppsInfinite(selection: FamilyActivitySelection, timeSet : Int) {
//    guard !tokens.isEmpty else {
//        print("No tokens provided")
//        return
//    }

    //double check authorization
    let authStatus = AuthorizationCenter.shared.authorizationStatus
    print("Authorization status: \(authStatus)")

    guard authStatus == .approved else {
        print("Screen Time authorization not granted")
        return
    }

    let store = ManagedSettingsStore()

    //blocker for individual apps
    if !selection.applicationTokens.isEmpty {
        print("Blocking \(selection.applicationTokens.count) individual apps")
        store.shield.applications = selection.applicationTokens
    }

    //blocker for categories
    if !selection.categoryTokens.isEmpty {
        print("Blocking \(selection.categoryTokens.count) categories")
        store.shield.applicationCategories = ShieldSettings.ActivityCategoryPolicy.specific(selection.categoryTokens)
    }

    //blocker for websites
    if !selection.webDomainTokens.isEmpty {
        print("Blocking \(selection.webDomainTokens.count) web domains")
        store.shield.webDomains = selection.webDomainTokens
    }

    guard !selection.applicationTokens.isEmpty || !selection.categoryTokens.isEmpty || !selection.webDomainTokens.isEmpty else {
        print("No tokens provided in selection")
        return
    }

    let now = Date()
    let cal = Calendar.current
    let start = cal.dateComponents([.hour, .minute, .second], from: now)
    guard let endDate = cal.date(byAdding: .minute, value: timeSet, to: now) else {
        print("Failed to create end date")
        return
    }

    let end = cal.dateComponents([.hour, .minute, .second], from: endDate)

    let schedule = DeviceActivitySchedule(
        intervalStart: DateComponents(hour: 0, minute: 0),
        intervalEnd: DateComponents(hour: 23, minute: 59),
        repeats: true
    )
    
    let name = DeviceActivityName("LMNT_Block")
    let center = DeviceActivityCenter()
    center.stopMonitoring([name])

    print("Schedule: \(start) to \(end)")

    do {
        try center.startMonitoring(name, during: schedule, events: [:])
    } catch {
        print("Failed to start monitoring: \(error)")
        if let deviceActivityError = error as? DeviceActivityCenter.MonitoringError {
            switch deviceActivityError {
            case .excessiveActivities:
                print("Too many activities running")
            case .unauthorized:
                print("Unauthorized")
            default:
                print("Unknown DeviceActivity error")
            }
        }
    }
}

func stopBlocking() {
    let store = ManagedSettingsStore()
    store.shield.applications = nil
    store.clearAllSettings()

    let center = DeviceActivityCenter()
    let activities = center.activities

    if !activities.isEmpty {
        center.stopMonitoring(Array(activities))
    }
}
//use this function when blocking less than 15 minutes
func shortBlocking(tokens: Set<ApplicationToken>) {
    guard AuthorizationCenter.shared.authorizationStatus == .approved else {
        print("Screen Time authorization not granted")
        return
    }

    guard !tokens.isEmpty else {
        print("No tokens provided")
        return
    }

    let store = ManagedSettingsStore()
    store.shield.applications = tokens

    DispatchQueue.main.asyncAfter(deadline: .now() + 10) {
        store.shield.applications = nil
    }
}

