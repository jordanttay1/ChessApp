//
//  ContentView.swift
//  AppTemplate
//
//  Created by Jordan Taylor on 4/21/25.
//

import SwiftUI

struct ContentView: View {
    // Receive the AuthViewModel from the environment
    @EnvironmentObject var authViewModel: AuthViewModel

    var body: some View {
        NavigationView { // Keep NavigationView for title and toolbar
            // Replace the VStack content with GameView
            GameView()
            // Remove padding that was applied to the old VStack
            .navigationTitle("Chess Game") // Update title to be more specific
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { // Keep the toolbar for the logout button
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Log Out") {
                        authViewModel.signOut()
                    }
                }
            }
        }
    }
}

// Preview Provider might need adjustment if GameView requires specific setup
// For now, let's keep it simple, assuming GameView initializes correctly.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        let previewAuthViewModel = AuthViewModel()
        // Simulate logged-in state for preview if needed
        // previewAuthViewModel.currentUser = ... 
        
        ContentView()
            .environmentObject(previewAuthViewModel)
    }
}
