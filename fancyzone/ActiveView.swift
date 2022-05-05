//
//  ActiveView.swift
//  fancyzone
//
//  Created by Trevor Starick on 2022-05-05.
//


import SwiftUI

struct SwiftUIView: View {
    let bounds = NSScreen.main?.frame
    var body: some View {
        ZStack{
        ForEach(handler.Zones) { zone in
            if !zone.Composite {
                ZStack {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.black.opacity(0.25))
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.blue, lineWidth: 2)
                }.frame(width: zone.Size.width, height: zone.Size.height)
                    .position(x: zone.Position.x + zone.Size.width / 2, y: zone.Position.y - 26 + zone.Size.height / 2)
            }
        }
        }
    }
}

struct SwiftUIView_Previews: PreviewProvider {
    static var previews: some View {
        SwiftUIView()
    }
}
