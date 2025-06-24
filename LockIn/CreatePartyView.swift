//
//  CreatePartyView.swift
//  LMNT
//
//  Created by Matthew Lu on 6/16/25.
//

import SwiftUI
import FirebaseFirestore
import FamilyControls
import DeviceActivity


//public view state so that other views can access if certain views are showing
public class CreatePartyViewState: ObservableObject {
    @Published var showFriendsSidebar = false
    @Published var isPresented = false
    @Published var isPressed = false
    @Published var showTimePicker = false
    @Published var selectedHours = 0
    @Published var selectedMinutes = 0
    @Published var isLeader = false
    @Published var showTimer = false
    @Published var timeRemaining: TimeInterval = 0

    //persisted timer info
    private(set) var timer: Timer?
    private(set) var endTime: Date?

    //family picker model
    @Published var selectionModel = ScreenTimeViewModel()

    //computed properties
    public var hasSelection: Bool {
        !(selectionModel.selectionToDiscourage.applicationTokens.isEmpty
         && selectionModel.selectionToDiscourage.categoryTokens.isEmpty
         && selectionModel.selectionToDiscourage.webDomainTokens.isEmpty)
    }

    public var hasValidTimeSelection: Bool {
        selectedHours != 0 || selectedMinutes != 0
    }

    public var buttonTitle: String {
        if showTimer { return "" }
        if isLeader {
            return (isPressed && hasSelection && hasValidTimeSelection) ? "Cancel" : "Ready Up"
        } else {
            return (isPressed && hasSelection) ? "Cancel" : "Ready Up"
        }
    }

    public func timeString(from seconds: Int) -> String {
        let h = seconds / 3600
        let m = (seconds % 3600) / 60
        let s = seconds % 60
        return String(format: "%02d:%02d:%02d", h, m, s)
    }

    //timer control
    public func startTimer(duration: TimeInterval) {
        endTime = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(endTime, forKey: "timerEndTime")
        UserDefaults.standard.set(true, forKey: "timerIsRunning")
        timeRemaining = duration
        scheduleNotification()
        beginInternalTimer()
    }

    private func beginInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let end = self.endTime else { return (self?.stopTimer())! }
            let remaining = end.timeIntervalSinceNow
            if remaining <= 0 {
                self.finishTimer()
            } else {
                DispatchQueue.main.async { self.timeRemaining = remaining }
            }
        }
    }

    public func stopTimer() {
        timer?.invalidate()
        timer = nil
        endTime = nil
        timeRemaining = 0
        showTimer = false
        UserDefaults.standard.removeObject(forKey: "timerEndTime")
        UserDefaults.standard.set(false, forKey: "timerIsRunning")
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    private func finishTimer() {
        stopTimer()
        showTimer = false
        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
    }
    
    //makes it so that we have persistent timer even if user exits the app
    public func restoreTimerIfNeeded() {
        let isRunning = UserDefaults.standard.bool(forKey: "timerIsRunning")
        guard isRunning,
              let savedEnd = UserDefaults.standard.object(forKey: "timerEndTime") as? Date
        else { return }
        let remaining = savedEnd.timeIntervalSinceNow
        if remaining <= 0 {
            finishTimer()
        } else {
            endTime = savedEnd
            timeRemaining = remaining
            beginInternalTimer()
        }
    }
    
    //schedules notification that the app block is done
    private func scheduleNotification() {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                guard granted else { return }
                let content = UNMutableNotificationContent()
                content.title = "Timer Finished"
                content.body  = "Your time block has completed!"
                content.sound = .default
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: self.timeRemaining,
                                                                repeats: false)
                let request = UNNotificationRequest(identifier: "timerComplete",
                                                    content: content,
                                                    trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
    }
}

//actual view
public struct CreatePartyView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @EnvironmentObject private var partyManager: PartySessionManager
    @StateObject private var partyVM = PartyViewModel()
    @StateObject private var state   = CreatePartyViewState()

    @Binding var path: NavigationPath
    let partyId: String
    private let bgImage = "image1_2005"

    public var body: some View {
        ZStack {
            BackgroundImageView(imageName: bgImage)
            VStack(spacing: 16) {
                inviteFriendsButton
                partyCodeText
                leavePartyButton

                if authVM.currentUser?.uid != nil {
                    Button(action: handleReadyUp) {
                        Text(state.buttonTitle)
                    }
                    .familyActivityPicker(isPresented: $state.isPresented,
                                          selection: $state.selectionModel.selectionToDiscourage)
                    .onChange(of: state.isPresented) { handlePickerChange() }
                    .onChange(of: state.showTimePicker) {handleTimeSelection() }

                    if state.showTimer {
                        timerSection
                    }
                }
            }
            .sheet(isPresented: $state.showFriendsSidebar) {
                FriendsSidebarView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $state.showTimePicker) {
                TimePickerView(
                    selectedHours: $state.selectedHours,
                    selectedMinutes: $state.selectedMinutes,
                    showTimePicker: $state.showTimePicker
                )
            }
            .onAppear {
                setupListeners()
                state.restoreTimerIfNeeded()
            }
            .onDisappear { removeListeners() }
            .onChange(of: authVM.userPartyCode) { resetNavigation() }
            .onChange(of: partyManager.allReady) { handleAllReady() }
        }
    }


    private var inviteFriendsButton: some View {
        Button(action: { state.showFriendsSidebar = true }) {
            HStack {
                Image(systemName: "person.2.fill")
                Text("Invite Friends")
            }
            .font(.custom("Palatino", size: 16))
            .fontWeight(.semibold)
            .foregroundColor(.white)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .background(Color.purple)
            .cornerRadius(10)
        }
    }

    private var partyCodeText: some View {
        Text("Party Code: \(partyId)")
            .foregroundColor(.white)
            .textSelection(.enabled)
    }

    private var leavePartyButton: some View {
        Button("Leave Party") {
            Task {
                await authVM.leaveParty(partyId: partyId)
                partyManager.allReady = false
                partyManager.leave()
            }
        }
    }

    @ViewBuilder
    private var timerSection: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                Text(state.timeString(from: Int(state.timeRemaining)))
                    .font(.system(size: 23, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)

                Button("Break!") {
                    state.startTimer(duration: 60)
                }
                .buttonStyle(.bordered)
                .disabled(state.timer == nil)

                Button("Leave!") {
                    state.stopTimer()
                    state.isPressed = false
                    partyManager.allReady = false
                }
                .buttonStyle(.bordered)
                .disabled(state.timer == nil)
            }
            .padding(20)
            .background(Color.gray.opacity(0.1))
            .cornerRadius(15)
        }
        .padding()
        .onAppear { state.restoreTimerIfNeeded() }
        .onReceive(NotificationCenter.default
                        .publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
            state.restoreTimerIfNeeded()
        }
    }
    
    //event handlers
    private func setupListeners() {
        guard let uid = authVM.currentUser?.uid,
              let email = authVM.currentUser?.email else { return }
        authVM.startListeningFriend(uid: uid)
        authVM.startListeningPartyCode(uid: uid)
        Task { state.isLeader = await partyVM.checkLeader(partyId: partyId, email: email) }
    }

    private func removeListeners() {
        authVM.stopListeningFriend()
        authVM.stopListeningPartyCode()
    }

    private func resetNavigation() {
        if authVM.userPartyCode.isEmpty {
            path = NavigationPath()
        }
    }

    private func handleAllReady() {
        guard partyManager.allReady else { return }
        let total = state.selectedHours * 60 + state.selectedMinutes
        partyManager.allReady = false
        blockApps(selection: state.selectionModel.selectionToDiscourage,
                          timeSet: total)
        state.showTimer = true
        state.startTimer(duration: TimeInterval(total * 60))
        Task { try await partyVM.clearReady(partyId: partyId) }
    }

    private func handleReadyUp() {
        if state.isPressed && state.hasSelection {
            Task { await authVM.cancelReady(partyId: partyId) }
            state.isPressed = false
            state.selectionModel.selectionToDiscourage = FamilyActivitySelection()
        } else {
            state.isPressed = true
            state.selectionModel.selectionToDiscourage = FamilyActivitySelection()
            state.isPresented = true
        }
    }

    private func handlePickerChange() {
        if state.isLeader {
            if !state.isPresented && state.hasSelection {
                state.showTimePicker = true
            }
        } else if !state.isPresented && state.hasSelection {
            state.isPressed = true
            Task { try await partyVM.readyUp(partyId: partyId,
                                             email: authVM.currentUser?.email ?? "") }
        }
    }

    private func handleTimeSelection() {
        if !state.showTimePicker && state.hasValidTimeSelection {
            state.isPressed = true
            Task { try await partyVM.readyUp(partyId: partyId,
                                             email: authVM.currentUser?.email ?? "") }
        }
    }
}

//view for picking time
struct TimePickerView: View {
    @Binding var selectedHours: Int
    @Binding var selectedMinutes: Int
    @Binding var showTimePicker: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("How long to block apps?")
                .font(.headline)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Hours")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Hours", selection: $selectedHours) {
                        ForEach(0..<24, id: \.self) { hour in
                            Text("\(hour)")
                                .tag(hour)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }
                
                VStack {
                    Text("Minutes")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Picker("Minutes", selection: $selectedMinutes) {
                        ForEach([0, 15, 30, 45], id: \.self) { minute in
                            Text("\(minute)")
                                .tag(minute)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 80)
                }
            }
            
            Text("Block for: \(selectedHours)h \(selectedMinutes)m")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button("Done!") {
                showTimePicker = false
                print("Block Time Set!")
            }
            .padding(.top)
            .buttonStyle(.borderedProminent)
            .disabled(selectedHours == 0 && selectedMinutes == 0)
        }
        .padding()
    }
}

//how the friend sidebar looks
extension CreatePartyView {
    struct FriendsSidebarView: View {
        @EnvironmentObject private var authVM: AuthViewModel
        @Environment(\.dismiss) private var dismiss
        @State private var selectedFriends: Set<String> = []
        
        var body: some View {
            NavigationView {
                VStack(spacing: 0) {
                    // Header
                    VStack(spacing: 12) {
                        Text("Invite Friends to Party")
                            .font(.custom("SF Pro", size: 24))
                            .fontWeight(.bold)
                            .foregroundColor(.primary)
                        
                        Text("Select friends to invite")
                            .font(.custom("SF Pro", size: 16))
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 20)
                    
                    //friends List
                    if authVM.friends.isEmpty {
                        VStack(spacing: 16) {
                            Image(systemName: "person.2.slash")
                                .font(.system(size: 48))
                                .foregroundColor(.gray)
                            
                            Text("No friends to invite")
                                .font(.custom("SF Pro", size: 18))
                                .fontWeight(.medium)
                                .foregroundColor(.secondary)
                            
                            Text("Add some friends first!")
                                .font(.custom("SF Pro", size: 14))
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(authVM.friends, id: \.self) { friend in
                                    FriendInviteRow(
                                        friendName: friend,
                                        isSelected: selectedFriends.contains(friend),
                                        onToggle: {
                                            if selectedFriends.contains(friend) {
                                                selectedFriends.remove(friend)
                                            } else {
                                                selectedFriends.insert(friend)
                                            }
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100) // Space for bottom button
                        }
                    }
                    
                    Spacer()
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        Button("Send Invites") {
                            Task {
                                await authVM.sendPartyInvite(selectedFriends: selectedFriends)
                                dismiss()
                            }
                        }
                        .disabled(selectedFriends.isEmpty)
                        .fontWeight(.semibold)
                    }
                }
            }
            .presentationDetents([.medium, .large])
            .presentationDragIndicator(.visible)
        }
    }
    
    //individual Friend Row for Selection
    struct FriendInviteRow: View {
        let friendName: String
        let isSelected: Bool
        let onToggle: () -> Void
        
        var body: some View {
            Button(action: onToggle) {
                HStack(spacing: 12) {
                    //avatar
                    Image(systemName: "person.crop.circle.fill")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .foregroundColor(isSelected ? .purple : .blue)
                    
                    //friend name
                    Text(friendName)
                        .font(.custom("SF Pro", size: 16))
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    //selection indicator
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 24))
                        .foregroundColor(isSelected ? .purple : .gray)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.purple.opacity(0.1) : Color(.secondarySystemBackground))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(isSelected ? Color.purple : Color.clear, lineWidth: 2)
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}
