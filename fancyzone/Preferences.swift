//
//  Preferences.swift
//  fancyzone
//
//  Created by Trevor Starick on 2021-11-24.
//

import SwiftUI

struct Preferences: View {
    var body: some View {
        ZStack {
            EmptyView()
        }
        .padding()
        .frame(
            minWidth: 128, idealWidth: 128, maxWidth: .infinity,
            minHeight: 82, idealHeight: 82, maxHeight: .infinity,
            alignment: .leading
        )
    }
}

struct Preferences_Previews: PreviewProvider {
    static var previews: some View {
        Preferences()
    }
}
