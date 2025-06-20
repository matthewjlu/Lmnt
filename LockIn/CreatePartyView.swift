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
    @State private var isPresented = false
    @State private var isPressed = false
    @State private var showTimePicker = false
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
            return (isPressed && hasSelection && (selectedHours != 0 || selectedMinutes != 0)) ? "Cancel" : "Ready Up"
        } else {
            return (isPressed && hasSelection) ? "Cancel" : "Ready Up"
        }
    }
    
    public var body: some View {
        ZStack {
            BackgroundImageView(imageName: bgImage)
            
            VStack(spacing: 16) {
                //invite Friends Button
                Button(action: {
                    showFriendsSidebar = true
                }) {
                    HStack {
                        Image(systemName: "person.2.fill")
                        Text("Invite Friends")
                    }
                    .font(.custom("SF Pro", size: 16))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.vertical, 12)
                    .padding(.horizontal, 24)
                    .background(Color.purple)
                    .cornerRadius(10)
                }
                
                Text("Party Code: \(partyId)")
                    .foregroundColor(.white)
                    .textSelection(.enabled)
                
                Button("Leave Party") {
                    Task {
                        await authVM.leaveParty(partyId: partyId)
                        partyManager.allReady = false
                        partyManager.leave()
                    }
                }
                
                if let _ = authVM.currentUser?.uid, let email = authVM.currentUser?.email {
                    Button {
                          //this is logic for cancel button
                          if isPressed && hasSelection {
                            Task {
                                await authVM.cancelReady(partyId: partyId)
                            }
                            isPressed = false
                            model.selectionToDiscourage = FamilyActivitySelection()
                            print("Cancelled blocking; picker will re-appear next time")
                         //this is logic for ready up button
                          } else {
                            isPressed = true
                            model.selectionToDiscourage = FamilyActivitySelection()
                            isPresented = true
                          }
                        } label: {
                          Text(buttonTitle)
                        }
                        .familyActivityPicker(isPresented: $isPresented, selection: $model.selectionToDiscourage)
                        //make it so that the leader readies up only if they pick a valid time
                        .onChange(of: showTimePicker) {
                            if !showTimePicker && (selectedHours != 0 || selectedMinutes != 0) {
                                Task {
                                    do {
                                        try await vm.readyUp(partyId: partyId, email: email)
                                    } catch {
                                        print("readyUp failed:", error)
                                    }
                                }
                            }
                        }
                        .onChange(of: isPresented) {
                            //make sure the user has exited the picker and has blocked something...also check if user is leader
                            Task {
                                if isLeader {
                                    if !isPresented && hasSelection {
                                        showTimePicker = true
                                    }
                                } else if !isPresented && hasSelection {
                                    Task {
                                        do {
                                            try await vm.readyUp(partyId: partyId, email: email)
                                        } catch {
                                            print("readyUp failed:", error)
                                        }
                                }
                            }
                        }
                    }
                    //this picks the time
                    .sheet(isPresented: $showTimePicker) {
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
                    
                    //the stack for the timer countdown
                    if showTimer {
                        VStack(spacing: 20) {
                            HStack(spacing: 20) {
                                Text(timeString(time: Int(timeRemaining)))
                                    .font(.system(size: 23, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Button("Break!") {
                                    //have to add break logic
                                    startTimer(duration: 60)
                                }
                                .buttonStyle(.bordered)
                                .bold(true)
                                .disabled(timer != nil)
                                .font(.custom("MarkaziText-Bold", size: 22))
                                
                                Button("Leave!") {
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
            }
            .sheet(isPresented: $showFriendsSidebar) {
                FriendsSidebarView()
                    .environmentObject(authVM)
            }
            .onAppear {
                //load friends when view appears
                if let uid = authVM.currentUser?.uid, let email = authVM.currentUser?.email {
                    authVM.startListeningFriend(uid: uid)
                    authVM.startListeningPartyCode(uid: uid)
                    Task {
                        isLeader = await vm.checkLeader(partyId: partyId, email: email)
                    }
                }
            }
            .onDisappear {
                authVM.stopListeningFriend()
                authVM.stopListeningPartyCode()
            }
            //checks if the party disbands so that we go back to home party view
            .onChange(of: authVM.userPartyCode) { _, _ in
                Task {
                    if authVM.userPartyCode == "" {
                        path = NavigationPath()
                    }
                }
            }
            //logic to check if everyone in the party is ready so that we can block the time
            .onChange(of: partyManager.allReady) {
                if partyManager.allReady {
                    //convert everything to minutes and calculate how much time we need to block for
                    blockApps(selection: model.selectionToDiscourage, timeSet: selectedHours * 60 + selectedMinutes)
                    showTimer = true
                    startTimer(duration: selectedHours * 3600 + selectedMinutes * 60)
                    Task {
                        try await vm.clearReady(partyId: partyId)
                    }
                }
            }
        }
    }
    
    private func startTimer(duration: TimeInterval) {
            // Store end time in UserDefaults for persistence
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
        //request permissoin from user for notification
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

    
    
    //friends Sidebar View
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

