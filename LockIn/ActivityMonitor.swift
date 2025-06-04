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

extension ManagedSettingsStore.Name {
    //need to define this so IOS knows which block we are talking about
    static let testBlock = Self("LMNT_BLOCK")
}

class ActivityMonitor: DeviceActivityMonitor{
    private var model = ScreenTimeViewModel()
    //let store = ManagedSettingsStore()
    
    let tokens: Set<ApplicationToken>
    let store = ManagedSettingsStore(named: .testBlock)
        
    init(tokens: Set<ApplicationToken>) {
        self.tokens = tokens
        super.init()
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        //let applications : Set<Application> = model.selectionToDiscourage.applications
        let tokens: Set<ApplicationToken> = model.selectionToDiscourage.applicationTokens
        //makes the var nil if empty or equal to tokens if it's not
        store.shield.applications = tokens.isEmpty ? nil : tokens
        print("APPS BLOCKED!")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        store.shield.applications = nil
        print("APPS UNBLOCKED")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        store.shield.applications = nil
    }
}

func blockApps() {
    let model = ScreenTimeViewModel()
    let appTokens = model.selectionToDiscourage.applicationTokens
    guard !appTokens.isEmpty else { return }
    
    let now = Date()
    let cal = Calendar.current
    let start = cal.dateComponents([.hour, .minute, .second], from: now)
    guard let endDate = cal.date(byAdding: .minute, value: 1, to: now) else { return }
    let end = cal.dateComponents([.hour, .minute, .second], from: endDate)
    
    let schedule = DeviceActivitySchedule(intervalStart: start, intervalEnd: end, repeats: false)
    //also tells IOS which device activity to fire callbacks for
    let name = DeviceActivityName("LMNT_Block")
    let center = DeviceActivityCenter()
    let events: [DeviceActivityEvent.Name: DeviceActivityEvent] = [:]
    //let m = ActivityMonitor(tokens: appTokens)
    do {
        try center.startMonitoring(name, during:  schedule, events: events)
        print("Monitoring started for X minutes.")
    } catch {
        print("Could not start monitoring: \(error)")
    }
}
