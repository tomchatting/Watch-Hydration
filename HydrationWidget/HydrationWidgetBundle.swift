//
//  HydrationWidgetBundle.swift
//  Watch Hydration
//
//  Created by Thomas Chatting on 21/05/2025.
//


//
//  HydrationWidgetBundle.swift
//  Watch Hydration WidgetExtension
//
//  Created by Thomas Chatting on 21/05/2025.
//

import WidgetKit
import SwiftUI

@main
struct HydrationWidgetBundle: WidgetBundle {
    var body: some Widget {
        HydrationWidget()
        HourlyHydrationWidget()
    }
}
