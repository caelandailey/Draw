//
//  ViewController.swift
//  Draw
//
//  Created by Caelan Dailey on 8/2/17.
//  Copyright © 2017 Caelan Dailey. All rights reserved.
//

import UIKit
import Firebase

class ViewController: UIViewController {
    
    //
    var lastPoint:CGPoint!
    var isSwiping:Bool!
    var red:CGFloat!
    var green:CGFloat!
    var blue:CGFloat!
    //
    @IBOutlet var imageView: UIImageView!
    @IBAction func saveImage(_ sender: AnyObject) {
        if self.imageView.image == nil{
            return
        }
        UIImageWriteToSavedPhotosAlbum(self.imageView.image!,self, #selector(ViewController.image(_:withPotentialError:contextInfo:)), nil)
    }
    @IBAction func undoDrawing(_ sender: AnyObject) {
        self.imageView.image = nil
    }
    func image(_ image: UIImage, withPotentialError error: NSErrorPointer, contextInfo: UnsafeRawPointer) {
        UIAlertView(title: nil, message: "Image successfully saved to Photos library", delegate: nil, cancelButtonTitle: "Dismiss").show()
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        loadLines()
        // Do any additional setup after loading the view, typically from a nib.
        red   = (0.0/255.0)
        green = (0.0/255.0)
        blue  = (0.0/255.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: Touch events
    override func touchesBegan(_ touches: Set<UITouch>,
                               with event: UIEvent?){
        isSwiping    = false
        if let touch = touches.first{
            lastPoint = touch.location(in: imageView)
        }
    }
    
    func loadLines() {
        let ref = Database.database().reference()
        
        
        ref.observe(.value, with: { snapshot in
 
            let enumerator = snapshot.children
            while let obj = enumerator.nextObject() as? DataSnapshot {
                
                var lastPointX: CGFloat = 0
                var lastPointY:CGFloat = 0
                var currentPointX:CGFloat = 0
                var currentPointY:CGFloat = 0
                
                for cell in obj.children.allObjects as! [DataSnapshot] {
                    
                    switch cell.key {
                    case "lastPointX": lastPointX = cell.value as! CGFloat
                    case "lastPointY": lastPointY = cell.value as! CGFloat
                    case "currentPointX": currentPointX = cell.value  as! CGFloat
                    case "currentPointY": currentPointY = cell.value  as! CGFloat
                    default: break
                    }
                }
                
                self.draw(lastPointX, firstPointY: lastPointY, nextPointX: currentPointX, nextPointY: currentPointY)
                
            }
        })
        
    }
    
    func draw(_ firstPointX: CGFloat, firstPointY: CGFloat, nextPointX: CGFloat, nextPointY: CGFloat) {
        
        if (abs(firstPointX - nextPointX) > 10) || (abs(firstPointY - nextPointY) > 10) {
            return
        }
        
        DispatchQueue.main.async {
            UIGraphicsBeginImageContext(self.imageView.frame.size)
            self.imageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height))
            
            
            UIGraphicsGetCurrentContext()?.move(to: CGPoint(x: nextPointX, y: nextPointY))
            UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x: firstPointX, y: firstPointY))
            UIGraphicsGetCurrentContext()?.setLineCap(CGLineCap.round)
            UIGraphicsGetCurrentContext()?.setLineWidth(9.0)
            UIGraphicsGetCurrentContext()?.setStrokeColor(red: self.red, green: self.green, blue: self.blue, alpha: 1.0)
            UIGraphicsGetCurrentContext()?.strokePath()
            self.imageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>,
                               with event: UIEvent?){
        
        isSwiping = true;
        if let touch = touches.first{
            let currentPoint = touch.location(in: imageView)
            UIGraphicsBeginImageContext(self.imageView.frame.size)
            self.imageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height))
            
            let savePoint = lastPoint!
            lastPoint =  currentPoint
            
            let x = Int(currentPoint.x)
            let y = Int(currentPoint.y)
            
            let itemRef = Database.database().reference().child("\(x),\(y)")
            
            itemRef.child("lastPointX").setValue(savePoint.x)
            itemRef.child("lastPointY").setValue(savePoint.y)
            itemRef.child("currentPointX").setValue(currentPoint.x)
            itemRef.child("currentPointY").setValue(currentPoint.y)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>,
                               with event: UIEvent?){
        if(!isSwiping) {
            // This is a single touch, draw a point
            UIGraphicsBeginImageContext(self.imageView.frame.size)
            self.imageView.image?.draw(in: CGRect(x: 0, y: 0, width: self.imageView.frame.size.width, height: self.imageView.frame.size.height))
            UIGraphicsGetCurrentContext()?.setLineCap(CGLineCap.round)
            UIGraphicsGetCurrentContext()?.setLineWidth(9.0)
            UIGraphicsGetCurrentContext()?.setStrokeColor(red: red, green: green, blue: blue, alpha: 1.0)
            UIGraphicsGetCurrentContext()?.move(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
            UIGraphicsGetCurrentContext()?.addLine(to: CGPoint(x: lastPoint.x, y: lastPoint.y))
            UIGraphicsGetCurrentContext()?.strokePath()
            self.imageView.image = UIGraphicsGetImageFromCurrentImageContext()
            UIGraphicsEndImageContext()
        }
    }}
