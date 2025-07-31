//
//  UploadServerError.swift
//  MusicApp
//
//  Created by Nhat Nguyen on 7/28/25.
//

import Foundation

enum ServerError: Error {
    case startFailed
    case stopFailed
    case configurationInvalid
}
