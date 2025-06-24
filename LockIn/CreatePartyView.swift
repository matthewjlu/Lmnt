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

public struct CreatePartyView: View {
    @EnvironmentObject private var authVM: AuthViewModel
    @StateObject private var model = ScreenTimeViewModel()
    @EnvironmentObject var partyManager : PartySessionManager
    @StateObject private var vm = PartyViewModel()
    @State private var showFriendsSidebar = false
    //toggles the friend sidebar, the family picker, and the time selector
    @State private var isPresented = false
    //deals with the ready up / cancel button
    @State private var isPressed = false
    @State private var showTimePicker = false
    //measures when to queue the stop timer functionalities
    @State private var partyTime: Date = .now
    @State private var selectedHours = 0
    @State private var selectedMinutes = 0
    @State private var isLeader = false
    //toggles for when the timer should show
    @State private var showTimer = false
    @State private var timeRemaining: TimeInterval = 0
    @State private var timer: Timer?
    @State private var endTime: Date?
    //binding creates a two way connection between this view and HomePartyView
    @Binding var path: NavigationPath
    let partyId : String
    private let bgImage = "image1_2005"
    
    private var hasSelection: Bool {
      !(
        model.selectionToDiscourage.applicationTokens.isEmpty
        && model.selectionToDiscourage.categoryTokens.isEmpty
        && model.selectionToDiscourage.webDomainTokens.isEmpty
      )
    }

    private var buttonTitle: String {
        if showTimer {
            return ""
        }
        if isLeader {
            return (isPressed && hasSelection && hasValidTimeSelection) ? "Cancel" : "Ready Up"
        } else {
            return (isPressed && hasSelection) ? "Cancel" : "Ready Up"
        }
    }
    
    //helper computed properties to break up complex expressions
    private var shouldShowReadyButton: Bool {
        authVM.currentUser?.uid != nil && authVM.currentUser?.email != nil
    }
    
    private var userEmail: String {
        authVM.currentUser?.email ?? ""
    }
    
    private var hasValidTimeSelection: Bool {
        selectedHours != 0 || selectedMinutes != 0
    }
    
    public var body: some View {
        ZStack {
            BackgroundImageView(imageName: bgImage)
            
            VStack(spacing: 16) {
                inviteFriendsButton
                partyCodeText
                leavePartyButton
                
                if shouldShowReadyButton {
                    Button {
                        handleReadyUpButtonTap()
                    } label: {
                        Text(buttonTitle)
                    }
                    .familyActivityPicker(isPresented: $isPresented, selection: $model.selectionToDiscourage)
                    .onChange(of: showTimePicker) {
                        handleTimePickerChange()
                    }
                    .onChange(of: isPresented) {
                        handlePickerPresentationChange()
                    }
                    
                    timerSection
                }
            }
            .sheet(isPresented: $showFriendsSidebar) {
                FriendsSidebarView()
                    .environmentObject(authVM)
            }
            .sheet(isPresented: $showTimePicker) {
                TimePickerView(
                    selectedHours: $selectedHours,
                    selectedMinutes: $selectedMinutes,
                    showTimePicker: $showTimePicker
                )
            }
            .onAppear {
                handleViewAppear()
            }
            .onDisappear {
                handleViewDisappear()
            }
            .onChange(of: authVM.userPartyCode) { _, _ in
                handlePartyCodeChange()
            }
            .onChange(of: partyManager.allReady) {
                handleAllReadyChange()
            }
        }
    }
    
    //different view components
    private var inviteFriendsButton: some View {
        Button(action: {
            showFriendsSidebar = true
        }) {
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
    
    //tag allows us to write more than one view
    @ViewBuilder
    private var timerSection: some View {
        if showTimer {
            VStack(spacing: 20) {
                HStack(spacing: 20) {
                    Text(timeString(time: Int(timeRemaining)))
                        .font(.system(size: 23, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Button("Break!") {
                        startTimer(duration: 60)
                    }
                    .buttonStyle(.bordered)
                    .bold(true)
                    .disabled(timer != nil)
                    .font(.custom("MarkaziText-Bold", size: 22))
                    
                    Button("Leave!") {
                        Task {
                            stopBlocking()
                        }
                        breakTimer()
                    }
                    .buttonStyle(.bordered)
                    .bold(true)
                    .disabled(timer == nil)
                    .font(.custom("MarkaziText-Bold", size: 22))
                }
                .padding(20)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(15)
            }
            .padding()
            .onAppear {
                checkForRunningTimer()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                checkForRunningTimer()
            }
        }
    }
    
    //event handlers
    private func handleViewAppear() {
        guard let uid = authVM.currentUser?.uid,
              let email = authVM.currentUser?.email else { return }
        
        authVM.startListeningFriend(uid: uid)
        authVM.startListeningPartyCode(uid: uid)
        
        Task {
            isLeader = await vm.checkLeader(partyId: partyId, email: email)
        }
    }
    
    private func handleViewDisappear() {
        authVM.stopListeningFriend()
        authVM.stopListeningPartyCode()
    }
    
    private func handlePartyCodeChange() {
        Task {
            if authVM.userPartyCode == "" {
                path = NavigationPath()
            }
        }
    }
    
    private func handleAllReadyChange() {
        if partyManager.allReady {
            let totalMinutes = selectedHours * 60 + selectedMinutes
            let totalSeconds = selectedHours * 3600 + selectedMinutes * 60
            
            blockApps(selection: model.selectionToDiscourage, timeSet: totalMinutes)
            showTimer = true
            startTimer(duration: TimeInterval(totalSeconds))
            
            Task {
                try await vm.clearReady(partyId: partyId)
            }
        }
    }
    
    private func handleReadyUpButtonTap() {
        print("Button tapped - isPressed: \(isPressed), hasSelection: \(hasSelection)")
        
        if isPressed && hasSelection {
            //cancel logic
            print("Cancelling...")
            Task {
                await authVM.cancelReady(partyId: partyId)
            }
            isPressed = false
            model.selectionToDiscourage = FamilyActivitySelection()
            print("Cancelled blocking; picker will re-appear next time")
        } else {
            //ready up logic - show picker
            print("Showing family picker...")
            isPressed = true
            model.selectionToDiscourage = FamilyActivitySelection()
            isPresented = true
        }
    }
    
    private func handleTimePickerChange() {
        if !showTimePicker && hasValidTimeSelection {
            //set isPressed to true when time is selected and ready up is called
            isPressed = true
            Task {
                do {
                    try await vm.readyUp(partyId: partyId, email: userEmail)
                } catch {
                    print("readyUp failed:", error)
                }
            }
        }
    }
    
    private func handlePickerPresentationChange() {
        if isLeader {
            if !isPresented && hasSelection {
                showTimePicker = true
            }
        } else if !isPresented && hasSelection {
            // For non-leaders, set isPressed immediately after selection
            isPressed = true
            Task {
                do {
                    try await vm.readyUp(partyId: partyId, email: userEmail)
                } catch {
                    print("readyUp failed:", error)
                }
            }
        }
    }
    
    //all the timer functions
    private func startTimer(duration: TimeInterval) {
        //store end time in UserDefaults for persistence
        endTime = Date().addingTimeInterval(duration)
        UserDefaults.standard.set(endTime, forKey: "timerEndTime")
        UserDefaults.standard.set(true, forKey: "timerIsRunning")
        
        timeRemaining = duration
        startInternalTimer()
        
        //schedule local notification
        scheduleNotification()
    }
    
    //start out timer so we know when to stop everything
    private func startInternalTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard let endTime = self.endTime else {
                breakTimer()
                return
            }
            
            let remaining = endTime.timeIntervalSinceNow
            if remaining <= 0 {
                //timer finished
                timerFinished()
            } else {
                timeRemaining = remaining
            }
        }
    }
    
    //if the user further down the line decides to take a break
    private func breakTimer() {
        timer?.invalidate()
        timer = nil
        endTime = nil
        timeRemaining = 0
        showTimer = false
        
        //clear the persistent data
        UserDefaults.standard.removeObject(forKey: "timerEndTime")
        UserDefaults.standard.set(false, forKey: "timerIsRunning")
        
        //cancel the notifcation that was supposed to be sent out
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    //checks if timer finished without sending notification
    private func timerFinished() {
        breakTimer()
        print("Timer finished!")
        showTimer = false
        
        //trigger haptic feedback if app is active
        let impactFeedback = UIImpactFeedbackGenerator(style: .heavy)
        impactFeedback.impactOccurred()
    }
    
    //this is to keep the timer running if we switch views or close app
    private func checkForRunningTimer() {
        let isRunning = UserDefaults.standard.bool(forKey: "timerIsRunning")
        
        if isRunning, let savedEndTime = UserDefaults.standard.object(forKey: "timerEndTime") as? Date {
            let remaining = savedEndTime.timeIntervalSinceNow
            
            if remaining <= 0 {
                //timer finished
                timerFinished()
            } else {
                //timer is still running so please continue
                endTime = savedEndTime
                timeRemaining = remaining
                startInternalTimer()
            }
        }
    }
    
    private func scheduleNotification() {
        //request permission from user for notification
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                let content = UNMutableNotificationContent()
                content.title = "Timer Finished"
                content.body = "Your time block has completed!"
                content.sound = .default
                
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeRemaining, repeats: false)
                let request = UNNotificationRequest(identifier: "timerComplete", content: content, trigger: trigger)
                
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
    
    //this formats the timer
    private func timeString(time: Int) -> String {
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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

#Preview {
    @Previewable @State var path: NavigationPath = {
        var p = NavigationPath()
        p.append(Route.createParty(id: "xZMKuxEfVX"))
        return p
    }()
    
    CreatePartyView(path: $path, partyId: "xZMKuxEfVX")
        .environmentObject(AuthViewModel())
        .environmentObject(PartySessionManager())
}
