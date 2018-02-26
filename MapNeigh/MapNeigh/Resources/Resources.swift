//
//  Resources.swift
//  MapNeigh
//
//  Created by Rodrigo Salles Stefani on 25/02/18.
//  Copyright © 2018 Rodrigo Salles Stefani. All rights reserved.
//

import Foundation
import Firebase

class Resources{
    
    static var main = Resources()
    
    let defaults = UserDefaults.standard
    
    init() {
        FirebaseApp.configure()
        
        let everIniciated = UserDefaults.standard.integer(forKey: "everstarted")
        
        if everIniciated == 0{
            savedItens()
        }else{
            print("Ja criou save")
        }
    }
    
    func savedItens(){
        print("entrou 1 vez")
        defaults.set("none", forKey: "lastFeeling")
        defaults.set(true, forKey: "everstarted")
        //UserDefaults.standard.set("Andgry", forKey: "lastFeeling")
    }

}

