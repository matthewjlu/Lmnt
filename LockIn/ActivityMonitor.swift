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
    
    let store = ManagedSettingsStore(named: .testBlock)
    //need to make this static so that when Apple creates its own instance it still sees the tokens it needs to block
    private static var tokensToBlock: Set<ApplicationToken> = []
    
    //we need to make it a static function so that it can access the static var tokensToBlock
    static func setTokens(_ tokens: Set<ApplicationToken>) {
        tokensToBlock = tokens
    }
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        //Self is a static property while self is an instance property
        store.shield.applications = Self.tokensToBlock.isEmpty ? nil : Self.tokensToBlock
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

func blockApps(tokens: Set<ApplicationToken>) {
    
    guard !tokens.isEmpty else { return }
    ActivityMonitor.setTokens(tokens)
    
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
    do {
        try center.startMonitoring(name, during:  schedule, events: events)
        print("Monitoring started for X minutes.")
    } catch {
        print("Could not start monitoring: \(error)")
    }
}
