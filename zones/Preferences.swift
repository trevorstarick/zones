//
//  Preferences.swift
// zones
//
//  Created by Trevor Starick on 2021-11-24.
//

import SwiftUI

struct Preferences: View {
    @AppStorage("outerGaps") var outerGaps: Double = 4
    @AppStorage("innerGaps") var innerGaps: Double = 8
    @AppStorage("onTop") var onTop: Bool = true
    @AppStorage("splitLast") var splitLast: Bool = true
    @AppStorage("columns") var columns: Int = 0
    
    var body: some View {
        Form {
            TextField("Outer Gaps:", value: $outerGaps, formatter: NumberFormatter())
            TextField("Inner Gaps:", value: $innerGaps, formatter: NumberFormatter())
            
            Picker("Number of Columns:", selection: $columns) {
                Text("Auto").tag(0)
                Text("1").tag(1)
                Text("2").tag(2)
                Text("3").tag(3)
                Text("4").tag(4)
                Text("5").tag(5)
            }
            
            Toggle("Keep Overlay On Top", isOn: $onTop)
            Toggle("Split Last Column", isOn: $splitLast)
            Spacer()
        }
        .padding()
        .frame(
            width: 640 / 2, height: 960 / 2, alignment: .leading
        )
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
    }
}
