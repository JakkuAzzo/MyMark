//
//  MatchItem.swift
//  MyMarkDemo
//
//  Created by Nathan Brown-Bennett on 5/12/25.
//

import Foundation

struct MatchItem: Identifiable, Decodable, Equatable {
    let id: Int
    let imageName: String
    let site: String
}
