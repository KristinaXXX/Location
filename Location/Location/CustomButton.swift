//
//  CustomButton.swift
//  Location
//
//  Created by Kr Qqq on 05.12.2023.
//

import Foundation
import UIKit

final class CustomButton: UIButton {

    typealias Action = () -> Void
        
    private let buttonAction: Action
    
    init(title: String, buttonAction: @escaping Action) {
        
        self.buttonAction = buttonAction
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        setTitle(title, for: .normal)
        backgroundColor = .white
        setTitleColor(.tintColor, for: .normal)
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        layer.cornerRadius = 10
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        buttonAction()
    }
}

final class CustomButtonImage: UIButton {

    typealias Action = () -> Void
        
    private let buttonAction: Action
    
    init(image: String, buttonAction: @escaping Action) {
        
        self.buttonAction = buttonAction
        super.init(frame: .zero)

        translatesAutoresizingMaskIntoConstraints = false
        addTarget(self, action: #selector(buttonTapped), for: .touchUpInside)
        layer.cornerRadius = 5
        backgroundColor = .white
        
        guard let imageUI = UIImage(systemName: image) else { return }
        setImage(imageUI.imageWith(newSize: CGSize(width: 25, height: 30)).withTintColor(.lightGray), for: .normal)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc private func buttonTapped(_ sender: UIButton) {
        buttonAction()
    }
}

extension UIImage {
    func imageWith(newSize: CGSize) -> UIImage {
        let image = UIGraphicsImageRenderer(size: newSize).image { _ in
            draw(in: CGRect(origin: .zero, size: newSize))
        }
        return image.withRenderingMode(renderingMode)
    }
}
