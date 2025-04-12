//
//  EditSheetViewModel.swift
//  PhotoSafe
//
//  Created by Abraham Mitchell on 4/10/25.
//

import Foundation


final class EditSheetViewModel: ObservableObject {
    @Published var album_name: String = ""
    @Published var is_locked: Bool = false
    @Published var initial_password: String = ""
 
    @Published var has_user_started_typing_initial: Bool = false
 
    func did_album_name_change(from album: AlbumEntity) -> Bool {
        self.album_name == album.name
    }
    
    func reset_password() {
        if !self.is_locked {
            self.initial_password = ""
        }
    }
    
    func remove_last_from_album_name() {
        if self.album_name.count > 15 {
            self.album_name.removeLast()
        }
    }

    func reset_initial(with new: String) {
        if !self.has_user_started_typing_initial {
            self.initial_password = self.initial_password.isEmpty ? "" : String(new.last!)
            self.has_user_started_typing_initial = true
        }
    }
    
    func set_variables(from album: AlbumEntity) {
        self.album_name = album.name
        self.is_locked = album.is_locked
        self.initial_password = album.password
    }
}
