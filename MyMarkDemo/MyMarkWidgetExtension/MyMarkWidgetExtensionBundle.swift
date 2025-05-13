//
//  MyMarkWidgetExtensionBundle.swift
//  MyMarkWidgetExtension
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import WidgetKit
import SwiftUI

@main
struct MyMarkWidgetExtensionBundle: WidgetBundle {
    var body: some Widget {
        MyMarkWidgetExtension()
        MyMarkWidgetExtensionControl()
        MyMarkWidgetExtensionLiveActivity()
    }
}
