//
//  SudoSudokuApp.swift
//  SudoSudoku
//
//  Created by Kai T. Chen on 2025/12/5.
//

import SwiftUI

@main
struct SudoSudokuApp: App {
    init() {
        CloudSyncManager.startForApp()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
