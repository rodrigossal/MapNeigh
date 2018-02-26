//
//  Resources.swift
//  MapNeigh
//
//  Created by Rodrigo Salles Stefani on 25/02/18.
//  Copyright © 2018 Rodrigo Salles Stefani. All rights reserved.
//

import Foundation
import Firebase
import CoreLocation

class Resources{
    
    static var main = Resources()
    
    let defaults = UserDefaults.standard
    
    init() {
        
        
        let everIniciated = UserDefaults.standard.integer(forKey: "everstarted")
        
        if everIniciated == 0{
            savedItens()
        }else{
            print("Ja criou save")
        }
    }
    
    func savedItens(){
        print("entrou 1 vez")
        let feeling = [String]()
        let posLa = [CLLocationDegrees]()
        let posLo = [CLLocationDegrees]()
        defaults.set(feeling, forKey: "feeling")
        defaults.set(posLa, forKey: "posLa")
        defaults.set(posLo, forKey: "posLo")
        
        defaults.set(true, forKey: "everstarted")
        //UserDefaults.standard.set("Andgry", forKey: "lastFeeling")
    }

}

