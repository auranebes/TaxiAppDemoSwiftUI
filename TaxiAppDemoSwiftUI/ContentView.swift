//
//  ContentView.swift
//  TaxiAppDemoSwiftUI
//
//  Created by Arslan Abdullaev on 11.02.2022.
//

import SwiftUI
import MapKit
import CoreLocation

struct ContentView: View {
    var body: some View {
        Home()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

struct Home: View {
    
    @State var map = MKMapView()
    @State var manager = CLLocationManager()
    @State var alert = false
    @State var source: CLLocationCoordinate2D!
    @State var destination: CLLocationCoordinate2D!
    @State var name = ""
    @State var distance = ""
    @State var time = ""
    
    var body: some View{
        ZStack{
            VStack(spacing: 0){
                HStack{
                    VStack(alignment: .leading, spacing: 15){
                    Text("Pick a location")
                        .font(.title)
                    if self.destination != nil {
                        Text(self.name)
                            .fontWeight(.bold)
                        }
                    }
                    Spacer()
                }
                .padding()
                .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
                .background(Color.white)
                
                MapView(map: self.$map,
                        manager: self.$manager,
                        alert: self.$alert,
                        source: self.$source,
                        destination: self.$destination,
                        name: self.$name,
                        distance: self.$distance,
                        time: self.$time
                )
                    .onAppear {
                        self.manager.requestAlwaysAuthorization()
                    }
            }
        }
        .edgesIgnoringSafeArea(.all)
        .alert(isPresented: self.$alert) {
            Alert(title: Text("Error"), message: Text("Please enable location in settings"), dismissButton: .destructive(Text("Ok")))
        }
    }
}

struct MapView: UIViewRepresentable {
    func makeCoordinator() -> Coordinator {
        return MapView.Coordinator(parent: self)
    }
    
    @Binding var map: MKMapView
    @Binding var manager: CLLocationManager
    @Binding var alert: Bool
    @Binding var source: CLLocationCoordinate2D!
    @Binding var destination: CLLocationCoordinate2D!
    @Binding var name: String
    @Binding var distance: String
    @Binding var time: String
    
    func makeUIView(context: Context) -> some UIView {
        map.delegate = context.coordinator
        manager.delegate = context.coordinator
        map.showsUserLocation = true
        let gesture = UITapGestureRecognizer(target: context.coordinator,
                                             action: #selector(context.coordinator.tap(gesture:)))
        map.addGestureRecognizer(gesture)
        return map
    }
    
    func updateUIView(_ uiView: UIViewType, context: Context) {
        
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, CLLocationManagerDelegate{
        var parent: MapView
        init(parent: MapView) {
            self.parent = parent
        }
        
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            if status == .denied{
                self.parent.alert.toggle()
            } else {
                self.parent.manager.startUpdatingLocation()
            }
        }
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            let region = MKCoordinateRegion(center: locations.last!.coordinate,
                                            latitudinalMeters: 10000,
                                            longitudinalMeters: 10000)
            self.parent.source = locations.last!.coordinate
            self.parent.map.region = region
        }
        
        @objc func tap(gesture: UITapGestureRecognizer) {
            let location = gesture.location(in: self.parent.map)
            let mapLocation = self.parent.map.convert(location, toCoordinateFrom: self.parent.map)
            let point = MKPointAnnotation()
            
            point.subtitle = "Destination"
            point.coordinate = mapLocation
            
            self.parent.destination = mapLocation
            
            let decoder = CLGeocoder()
            decoder.reverseGeocodeLocation(CLLocation(latitude: mapLocation.latitude,
                                                      longitude: mapLocation.longitude)) { places, error in
                if error != nil {
                    print(error?.localizedDescription ?? "error")
                    return
                }
                
                self.parent.name = places?.first?.name ?? ""
                point.title = places?.first?.name ?? ""
            }
            
            let request = MKDirections.Request()
            request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.parent.source))
            request.destination = MKMapItem(placemark: MKPlacemark(coordinate: mapLocation))
            
            let directions = MKDirections(request: request)
            directions.calculate { (directions, error) in
                if error != nil {
                    print(error?.localizedDescription ?? "error")
                    return
                }
                
                guard let polyline = directions?.routes[0].polyline else {return}
                
                let distance = directions?.routes[0].distance as! Double
                
                self.parent.distance = String(distance)
                
                self.parent.map.removeOverlays(self.parent.map.overlays)
                
                self.parent.map.addOverlay(polyline)
                
                self.parent.map.setRegion(MKCoordinateRegion(polyline.boundingMapRect), animated: true)
            }
            
            self.parent.map.removeAnnotations(self.parent.map.annotations)
            self.parent.map.addAnnotation(point)
        }
        
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            let overlay = MKPolylineRenderer(overlay: overlay)
            overlay.strokeColor = .red
            overlay.lineWidth = 3
            return overlay
        }
    }
}
