//
//  TimWidgetBundle.swift
//  TimWidget
//
//  Created by Andrew De la Cruz on 6/2/25.
//

import WidgetKit
import SwiftUI

@main
struct TimWidgetBundle: WidgetBundle {
    init() {
        print("🚀 TimWidgetBundle: Widget bundle initialized!")
    }
    
    var body: some Widget {
        TimWidget()
        TimWidgetControl()
        TimWidgetLiveActivity()
    }
}
