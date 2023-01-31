//
//  ActiveView.swift
// zones
//
//  Created by Trevor Starick on 2022-05-05.
//


import SwiftUI

struct SwiftUIView: View {
    @ObservedObject var zones: Zones

    let bounds = NSScreen.main?.frame
    var body: some View {
        ZStack{
            ForEach($zones.zones, id: \.self) { $zone in
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.blue.opacity(zone.Hovered ? 0.2 : 0.1))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue, lineWidth: 2)
                }.frame(width: zone.Size.width, height: zone.Size.height)
                    .position(x: zone.Position.x + zone.Size.width / 2, y: zone.Position.y + zone.Size.height / 2)
            }
        }
    }
}
