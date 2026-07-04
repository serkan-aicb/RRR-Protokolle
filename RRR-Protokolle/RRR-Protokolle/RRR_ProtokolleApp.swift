//
//  RRR_ProtokolleApp.swift
//  RRR-Protokolle
//
//  Created by CORVUS on 03.07.26.
//

import SwiftUI

@main
struct RRR_ProtokolleApp: App {
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authViewModel)
        }
    }
}
