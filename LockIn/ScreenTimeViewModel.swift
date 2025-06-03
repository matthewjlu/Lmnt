//
//  ScreenTimeViewModel.swift
//  LMNT
//
//  Created by Matthew Lu on 6/3/25.
//

import FirebaseCore
import FirebaseAuth
import FirebaseFirestore
import FamilyControls

@MainActor
class ScreenTimeViewModel: ObservableObject {
    @Published var selectionToDiscourage: FamilyActivitySelection = .init()
    
    init() {
        
    }
}
