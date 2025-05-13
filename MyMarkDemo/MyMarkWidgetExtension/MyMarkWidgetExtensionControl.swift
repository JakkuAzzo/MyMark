//
//  MyMarkWidgetExtensionControl.swift
//  MyMarkWidgetExtension
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import SwiftUI
import WidgetKit

struct MyMarkWidgetEntryView: View {
    let entry: MyMarkEntry

    var body: some View {
        HStack(spacing: 8) {
            Image("MyMark")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)

            VStack(alignment: .leading) {
                if entry.totalProcessed == 0 {
                    Text("Syncing…")
                        .font(.headline)
                } else {
                    Text("Processed: \(entry.totalProcessed)")
                        .font(.headline)
                    Text("Matches: \(entry.potentialMatches)")
                        .font(.subheadline)
                }
            }
        }
        .padding()
    }
}

// If you have any widget control logic (e.g., timeline reload triggers), place it here.
// For now, no functions from Widget.swift need to be moved here unless you have custom reload logic.
