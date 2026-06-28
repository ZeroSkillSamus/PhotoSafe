//
//  OptionsViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 6/9/26.
//

import Foundation

@MainActor
class SlideShowViewModel: ObservableObject {
    // Settings for setting auto play
    @Published var showSettings: Bool = false
    @Published var autoPlayEnabled: Bool = false
    @Published var slideShowDirection: SlideShowType = .vertical
    @Published var timeInteval: TimeInterval = 2
    @Published var isShuffleEnabled: Bool = false
    
    
    @Published var displaySlideshow: Bool = false
    
    
    
    func showSlideShow() { self.displaySlideshow = true }
    func showSlideShowOptions () { showSettings = true }
}
