//
//  MapViewController.swift
//  Location
//
//  Created by Kr Qqq on 05.12.2023.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController {

    private lazy var mapView: MKMapView = {
        let view = MKMapView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.showsUserTrackingButton = true
        view.mapType = .standard
        view.showsUserLocation = true
        
        let longGesture = UILongPressGestureRecognizer(target: self, action: #selector(longPressMap))
        view.addGestureRecognizer(longGesture)
        
        let gesture = UITapGestureRecognizer(target: self, action: #selector(pressMap))
        view.addGestureRecognizer(gesture)
        
        return view
    }()
    
    private lazy var transportType: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.contentVerticalAlignment = .center
        segmentedControl.insertSegment(with: UIImage(systemName: "car")?.rotate(radians: -.pi/2), at: 0, animated: true)
        segmentedControl.insertSegment(with: UIImage(systemName: "figure.walk")?.rotate(radians: -.pi/2), at: 1, animated: true)
        segmentedControl.transform = CGAffineTransform(rotationAngle: .pi / 2.0)
        segmentedControl.selectedSegmentIndex = 0

        return segmentedControl
    }()
    
    private lazy var mapType: UISegmentedControl = {
        let segmentedControl = UISegmentedControl()
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.contentVerticalAlignment = .center
        segmentedControl.insertSegment(with: UIImage(systemName: "map")?.rotate(radians: -.pi/2), at: 0, animated: true)
        segmentedControl.insertSegment(with: UIImage(systemName: "binoculars")?.rotate(radians: -.pi/2), at: 1, animated: true)
        segmentedControl.transform = CGAffineTransform(rotationAngle: .pi / 2.0)
        segmentedControl.selectedSegmentIndex = 0
    
        segmentedControl.addTarget(self, action: #selector(switchMapType), for:.allEvents)

        return segmentedControl
    }()
    
    private lazy var trackButton = CustomButton(title: "Проложить маршрут", buttonAction: ( { self.trackButtonPressed() } ))
    private lazy var removeAnnotationsButton = CustomButtonImage(image: "mappin.slash", buttonAction: ( { self.removeAnnotationsButtonPressed() } ))
    
    private let manager = CLLocationManager()
    private var nowCoordinate: CLLocationCoordinate2D?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        addSubviews()
        setupConstraints()
        setupMap()
    }
    
    private func setupMap() {
        manager.delegate = self
        
        if manager.authorizationStatus == .notDetermined {
            manager.requestWhenInUseAuthorization()
        }
        manager.startUpdatingLocation()
        mapView.delegate = self
    }
    
    private func setupView() {
        trackButton.isHidden = true
    }
    
    func addSubviews() {
        view.addSubview(mapView)
        view.addSubview(trackButton)
        view.addSubview(transportType)
        view.addSubview(mapType)
        view.addSubview(removeAnnotationsButton)
    }
    
    func setupConstraints() {
        
        let safeAreaLayoutGuide = view.safeAreaLayoutGuide
        
        NSLayoutConstraint.activate([
            mapView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            mapView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            mapView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            mapView.topAnchor.constraint(equalTo: view.topAnchor)
        ])
        
        NSLayoutConstraint.activate([
            trackButton.centerXAnchor.constraint(equalTo: safeAreaLayoutGuide.centerXAnchor),
            trackButton.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor, constant: -40),
            trackButton.heightAnchor.constraint(equalToConstant: 35),
            trackButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -20),
            trackButton.leadingAnchor.constraint(equalTo: safeAreaLayoutGuide.leadingAnchor, constant: 20)
        ])
        
        NSLayoutConstraint.activate([
            transportType.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 100),
            transportType.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: 10)
        ])
        
        NSLayoutConstraint.activate([
            mapType.topAnchor.constraint(equalTo: transportType.bottomAnchor, constant: 50),
            mapType.trailingAnchor.constraint(equalTo: transportType.trailingAnchor, constant: -3)
        ])
        
        NSLayoutConstraint.activate([
            removeAnnotationsButton.topAnchor.constraint(equalTo: mapType.bottomAnchor, constant: 50),
            removeAnnotationsButton.trailingAnchor.constraint(equalTo: safeAreaLayoutGuide.trailingAnchor, constant: -16)
        ])
    }
    
    private func trackButtonPressed() {
        trackButton.isHidden = true
        guard let annotation = mapView.selectedAnnotations.first else { return }
        createRoute(to: annotation.coordinate)
    }
    
    private func removeAnnotationsButtonPressed() {
        mapView.removeAnnotations(mapView.annotations)
    }
    
    private func createRoute(to coordinateTo: CLLocationCoordinate2D) {
        mapView.removeOverlays(mapView.overlays)
        guard let coordinateFrom = nowCoordinate else { return }
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: coordinateFrom))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinateTo))
        switch transportType.selectedSegmentIndex {
        case 0:
            request.transportType = .automobile
        default:
            request.transportType = .walking
        }
        
        let directions = MKDirections(request: request)
        directions.calculate { [weak self] responce, error in
            guard let responce, let route = responce.routes.first else {
                if let error = error {
                    print("Error: \(error)")
                }
                return
            }
            self?.mapView.addOverlay(route.polyline)
            self?.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
        }
    }
    
    func addAnnotation(latitude: Double, longitude: Double, title: String) {
        let alert = UIAlertController(title: "Новая метка", message: nil, preferredStyle: .alert)
        alert.addTextField()
        alert.textFields![0].placeholder = "Название метки"
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Создать", style: .default, handler: { [weak self] _ in
            let annotation = MKPointAnnotation()
            annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            annotation.title = alert.textFields![0].text
            self?.mapView.addAnnotation(annotation)
        }))
        self.present(alert, animated: true)
    }
    
    @objc
    private func longPressMap(_ gr: UILongPressGestureRecognizer) {
        let point = gr.location(in: mapView)
        let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
        addAnnotation(latitude: coordinate.latitude, longitude: coordinate.longitude, title: "123")
    }
    
    @objc
    private func pressMap(_ gr: UILongPressGestureRecognizer) {
        trackButton.isHidden = true
    }
    
    @objc
    private func switchMapType() {
        switch mapType.selectedSegmentIndex {
        case 0:
            mapView.mapType = .standard
        default:
            mapView.mapType = .satellite
        }
    }
}

extension MapViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let coordinates = locations.first else { return }
        nowCoordinate = CLLocationCoordinate2D(latitude: coordinates.coordinate.latitude, longitude: coordinates.coordinate.longitude)
    }
}

extension MapViewController: MKMapViewDelegate {
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        trackButton.isHidden = false
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay)
        renderer.strokeColor = .tintColor
        renderer.lineWidth = 4.0
        return renderer
    }
}

extension UIImage {
    func rotate(radians: Float) -> UIImage? {
        var newSize = CGRect(origin: CGPoint.zero, size: self.size).applying(CGAffineTransform(rotationAngle: CGFloat(radians))).size
        // Trim off the extremely small float value to prevent core graphics from rounding it up
        newSize.width = floor(newSize.width)
        newSize.height = floor(newSize.height)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, self.scale)
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Move origin to middle
        context.translateBy(x: newSize.width/2, y: newSize.height/2)
        // Rotate around middle
        context.rotate(by: CGFloat(radians))
        // Draw the image at its center
        self.draw(in: CGRect(x: -self.size.width/2, y: -self.size.height/2, width: self.size.width, height: self.size.height))
    
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return newImage
    }
}

