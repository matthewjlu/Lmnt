//
//  DeviceActivityMonitorExtension.swift
//  monitor
//
//  Created by Matthew Lu on 6/5/25.
//
import Foundation
import ManagedSettings
import FamilyControls
import DeviceActivity

class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    private static let store = ManagedSettingsStore()
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        NSLog("🔴🔴🔴 BLOCKING STARTED!")
        super.intervalDidStart(for: activity)
        NSLog("🔴🔴🔴 BLOCKING START COMPLETED!")
    }
        
    override func intervalDidEnd(for activity: DeviceActivityName) {
        NSLog("🔴🔴🔴 Interval ended - clearing restrictions")
        super.intervalDidEnd(for: activity)
        Self.store.clearAllSettings()
        NSLog("🔴🔴🔴 All settings cleared")
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        Self.store.clearAllSettings()
    }
    
    override func intervalWillStartWarning(for activity: DeviceActivityName) {
        super.intervalWillStartWarning(for: activity)
        
        // Handle the warning before the interval starts.
    }
    
    override func intervalWillEndWarning(for activity: DeviceActivityName) {
        super.intervalWillEndWarning(for: activity)
        
        // Handle the warning before the interval ends.
    }
    
    override func eventWillReachThresholdWarning(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventWillReachThresholdWarning(event, activity: activity)
        
        // Handle the warning before the event reaches its threshold.
    }
}

