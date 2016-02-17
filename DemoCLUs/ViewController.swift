//
//  ViewController.swift
//  DemoCLUs
//
//  Created by Tommy Rogers on 2/16/16.
//  Copyright © 2016 Tommy Rogers. All rights reserved.
//

import UIKit
import MapKit
import LoginWithClimate
import GeoFeatures

class ViewController: UIViewController, LoginWithClimateDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var loginViewController: LoginWithClimateButton!
    
    // MARK: - ViewController functions
    
    override func viewDidLoad() {
        super.viewDidLoad()


        // Set up button
        
        loginViewController = LoginWithClimateButton(clientId: "", clientSecret: "")
        loginViewController.delegate = self
        
        view.addSubview(loginViewController.view)
        loginViewController.view.translatesAutoresizingMaskIntoConstraints = false

        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|-[button]-|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: ["button":loginViewController.view]))
        view.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:[button(==44)]-30-|", options: NSLayoutFormatOptions(rawValue: 0), metrics: nil, views: ["button":loginViewController.view]))
        
        self.addChildViewController(loginViewController)


        // Set up map

        mapView.delegate = self
        
        mapView.scrollEnabled = false
        mapView.rotateEnabled = false
        mapView.zoomEnabled = false

        let location = CLLocation(latitude: 40.123158, longitude: -88.086051)
        let region = MKCoordinateRegionMakeWithDistance(location.coordinate, 5000, 5000)
        mapView.setRegion(region, animated: false)
    }
    
    // MARK: - Utility functions
    
    func randomColor() -> UIColor {
        return UIColor(red: CGFloat(drand48()), green: CGFloat(drand48()), blue: CGFloat(drand48()), alpha: 1.0)
    }
    
    func clearMap() {
        dispatch_async(dispatch_get_main_queue()) {
            self.mapView.removeOverlays(self.mapView.overlays)
        }
    }

    func cornerCoordinatesForMapView(map: MKMapView) -> (CLLocationCoordinate2D, CLLocationCoordinate2D) {
        let nePoint = CGPointMake((map.bounds.origin.x + map.bounds.size.width), map.bounds.origin.y);
        let swPoint = CGPointMake(map.bounds.origin.x, (map.bounds.origin.y + map.bounds.size.height));
        
        //Then transform those point into lat,lng values
        let neCoord = map.convertPoint(nePoint, toCoordinateFromView: map)
        let swCoord = map.convertPoint(swPoint, toCoordinateFromView: map)
        
        return (neCoord, swCoord)
    }
    
    // MARK: - LoginWithClimate delegate functions
    
    func didLoginWithClimate(session: Session) {
        print("Logged in.")
        self.clearMap()
        self.drawCLUs(session.accessToken)
    }
    
    // MARK: - MKMapView delegate functions
    
    func mapView(mapView: MKMapView, rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        if (overlay.isKindOfClass(MKPolygon)) {
            let renderer = MKPolygonRenderer(overlay: overlay)
            let color = randomColor()
            renderer.strokeColor = color
            renderer.fillColor = color
            renderer.alpha = 0.5
            renderer.lineWidth = 1.0
            return renderer
        } else {
            print("ERROR: Found overlay of type \(overlay.dynamicType)")
            return MKOverlayRenderer()
        }
    }
    
    
    // MARK: - Business functions
    
    func drawCLUs(myAccessToken: String) {
        self.fetchCLUs(myAccessToken, corners: self.cornerCoordinatesForMapView(self.mapView)) {
            (response: [String: AnyObject]) in
            let clus = response["features"] as! [[String: AnyObject]]
            
            let overlays: [[MKOverlay]] = clus.map() {
                (clu: [String: AnyObject]) -> [MKOverlay] in
                let geometry = GFGeometry(geoJSONGeometry: clu["geometry"] as! [String: AnyObject])
                return geometry.mkMapOverlays() as! [MKOverlay]
            }
            
            dispatch_async(dispatch_get_main_queue()) {
                overlays.forEach() {
                    (os: [MKOverlay]) -> () in
                    self.mapView.addOverlays(os)
                }
            }
        }
    }
    
    func fetchCLUs(myAccessToken: String, corners: (neCoord: CLLocationCoordinate2D, swCoord: CLLocationCoordinate2D), completion: ([String: AnyObject] -> Void)) {
        let (neCoord, swCoord) = corners

        let components: NSURLComponents = NSURLComponents(string: "https://hackillinois.climate.com/api/clus")!
        components.queryItems = [NSURLQueryItem(name: "ne_lat", value: neCoord.latitude.description),
                                 NSURLQueryItem(name: "ne_lon", value: neCoord.longitude.description),
                                 NSURLQueryItem(name: "sw_lat", value: swCoord.latitude.description),
                                 NSURLQueryItem(name: "sw_lon", value: swCoord.longitude.description)]
        
        let request = NSMutableURLRequest(URL: components.URL!)
        request.setValue("Bearer \(myAccessToken)", forHTTPHeaderField: "Authorization")
        
        let task = NSURLSession.sharedSession().dataTaskWithRequest(request) {
            (data, response, error) in
            
            guard error == nil && (response as? NSHTTPURLResponse)?.statusCode == 200 else {
                print(error)
                print(response)
                print(NSString(data: data!, encoding: NSUTF8StringEncoding))
                return
            }
            
            let jsonObject = try! NSJSONSerialization.JSONObjectWithData(data!, options: []) as! [String: AnyObject]
            completion(jsonObject)
        }
        
        task.resume()
    }
}

