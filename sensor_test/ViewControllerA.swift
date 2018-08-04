import UIKit
import CoreMotion
import CoreLocation
import SwiftSocket

class ViewControllerA: UIViewController,CLLocationManagerDelegate {
        //
    struct SensorData: Codable {
        var timeStamp : String
        var boatnumber : String
        var position: Position_
        var accelaration : Accelaration
        var angular : Angular
        var direction : Direction_
    }

    struct Position_: Codable {
        var longitude: Float
        var latitude: Float
    }
    struct Accelaration: Codable {
        var x: Float
        var y: Float
        var z: Float
    }
    struct Angular: Codable {
        var x: Float
        var y: Float
        var z: Float
    }
    struct Direction_: Codable {
        var x: Float
        var y: Float
        var z: Float
    }
    
    
        let data = """
            {
                "GPS":{
                    "keido": keido,
                    "ido": ido
                    },
                "capacities": sample,
                "biometricsAuth": sample2
            }
            """.data(using: .utf8)!
    
    
        let motionManager = CMMotionManager()
        @IBOutlet var accelerometerX: UILabel!
        @IBOutlet var accelerometerY: UILabel!
        @IBOutlet var accelerometerZ: UILabel!
    
        //gyro
        @IBOutlet var gyro_xLabel: UILabel!;
        @IBOutlet var gyro_yLabel: UILabel!;
        @IBOutlet var gyro_zLabel: UILabel!;
        //GPS
        // インスタンスの生成
        var locationManager: CLLocationManager!
    
        // CLLocationManagerDelegateプロトコルを実装するクラスを指定する
        //locationManager.delegate = self
        @IBOutlet weak var latTextField: UITextField!
        @IBOutlet weak var lngTextField: UITextField!
    
        //direction
        @IBOutlet weak var Direction: UITextField!
    
        @IBAction func TouchTestButton(sender: AnyObject) {
            let now = NSDate()
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd HH:mm:ss"
            let date = formatter.string(from: now as Date)
            
            _ = SensorData(timeStamp : date,boatnumber:"1", position :Position_ ,accelaration:Accelaration,angular:Angular,direction:Direction_)
            let client = TCPClient(address: "192.168.100.100", port: 5000)
            client.send(data: data)
        }
   
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .blue
        
        //accelerometer
        if motionManager.isAccelerometerAvailable {
            // intervalの設定 [sec]
            motionManager.accelerometerUpdateInterval = 0.2
            
            // センサー値の取得開始
            motionManager.startAccelerometerUpdates(
                to: OperationQueue.current!,
                withHandler: {(accelData: CMAccelerometerData?, errorOC: Error?) in
                    self.outputAccelData(acceleration: accelData!.acceleration)
            })
        }
        
        if motionManager.isGyroAvailable  {
            // 更新間隔の指定
            motionManager.gyroUpdateInterval = 0.2  // 秒
            // ハンドラ
            //motionManager.startGyroUpdates()
            motionManager.startGyroUpdates(
                to: OperationQueue.current!,
                withHandler: {(gyroData: CMGyroData!, error: Error!)in
                self.outputGyroData(gyroData: gyroData.rotationRate)
                    if (error != nil)
                    {
                        print("\(error)")
                    }
                })
        }
        
        //GSP
        if CLLocationManager.locationServicesEnabled() {
            locationManager = CLLocationManager()
            locationManager.delegate = self
            locationManager.startUpdatingLocation()
            
            // 何度動いたら更新するか（デフォルトは1度）
            locationManager.headingFilter = kCLHeadingFilterNone
            // デバイスのどの向きを北とするか（デフォルトは画面上部）
            locationManager.headingOrientation = .portrait
            locationManager.startUpdatingHeading()
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
            break
        case .restricted, .denied:
            print("位置情報取得が拒否されました")
            break
        case .authorizedAlways, .authorizedWhenInUse:
            print("位置情報取得(起動時のみ)が許可されました")
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let newLocation = locations.last,
            CLLocationCoordinate2DIsValid(newLocation.coordinate) else {
                self.latTextField.text = "Error"
                self.lngTextField.text = "Error"
                return
        }
        
        let latitude = newLocation.coordinate.latitude
        let longitude = newLocation.coordinate.longitude
        self.latTextField.text = "".appendingFormat("%.4f", latitude)
        self.lngTextField.text = "".appendingFormat("%.4f", longitude)
        _ = Position_(longitude: Float(longitude), latitude: Float(latitude))
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        self.Direction.text = "".appendingFormat("%.2f", newHeading.magneticHeading)
        _ = Direction_(x:Direction)
    }
    
    // 位置情報取得に失敗した時に呼び出されるデリゲート.
    func locationManager(_ manager: CLLocationManager,didFailWithError error: Error){
        print("error")
    }
    
    func outputGyroData(gyroData: CMRotationRate){
        // 加速度センサー [G]
        let gyrox = gyroData.x
        let gyroy = gyroData.y
        let gyroz = gyroData.z
        gyro_xLabel.text = String(format: "%06f", gyrox)
        gyro_yLabel.text = String(format: "%06f", gyroy)
        gyro_zLabel.text = String(format: "%06f", gyroz)
        _ = Angular(x: Float(gyrox), y:Float(gyroy), z:Float(gyroz))
    }
    
    func outputAccelData(acceleration: CMAcceleration){
        // 加速度センサー [G]
        let accx = acceleration.x
        let accy = acceleration.y
        let accz = acceleration.z
        accelerometerX.text = String(format: "%06f", accx)
        accelerometerY.text = String(format: "%06f", accy)
        accelerometerZ.text = String(format: "%06f", accz)
        _ = Accelaration(x: Float(accx), y:Float(accy), z:Float(accz))
    }
    
    // センサー取得を止める場合
    func stopAccelerometer(){
        if (motionManager.isAccelerometerActive) {
            motionManager.stopAccelerometerUpdates()
        }
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        
    }
}



extension ViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        switch status {
        case .notDetermined:
            print("ユーザーはこのアプリケーションに関してまだ選択を行っていません")
            //locationManager.requestWhenInUseAuthorization()
            break
        case .denied:
            print("ローケーションサービスの設定が「無効」になっています (ユーザーによって、明示的に拒否されています）")
            // 「設定 > プライバシー > 位置情報サービス で、位置情報サービスの利用を許可して下さい」を表示する
            break
        case .restricted:
            print("このアプリケーションは位置情報サービスを使用できません(ユーザによって拒否されたわけではありません)")
            // 「このアプリは、位置情報を取得できないために、正常に動作できません」を表示する
            break
        case .authorizedAlways:
            print("常時、位置情報の取得が許可されています。")
            // 位置情報取得の開始処理
            break
        case .authorizedWhenInUse:
            print("起動時のみ、位置情報の取得が許可されています。")
            // 位置情報取得の開始処理
            break
        }
    }
}
