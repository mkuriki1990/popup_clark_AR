//
//  ViewController.swift
//  clark_statue
//
//  Created by Murahashi Kuriki on 2021/05/28.
//
/*
MIT License

Copyright (c) 2021 Murahashi Kuriki

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
*/
 
import UIKit
import SceneKit
import ARKit
import AudioToolbox

class ViewController: UIViewController, ARSCNViewDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var instruction_label: UILabel! // 最初の説明ラベル
    @IBOutlet weak var cp_label: UILabel! // ポイント表示用ラベル
    @IBOutlet weak var gold_switch: UISwitch! // 金色クラークの切り替えスイッチ
    @IBOutlet weak var license_textview: UITextView! // ライセンス表記分分
    @IBOutlet weak var erase_button: UIButton! // クラーク像消去ボタン
    let license_link = "Murahashi Kuriki" // ライセンス表示でリンクを貼る文字列
    let cp_limit = 99 // 金色クラークを許可する数
    var cp_counter = 0 // クラークポイントカウンター
    var isGoldFlag = false // 金色にするかどうかのフラグ
    var isGoldAnnouncedFlag = false // 金色のお知らせを出したかどうかのフラグ
    var isGoldToggle = false // 金色状態のオンオフのフラグ
    
    let userDefaults = UserDefaults.standard // UserDefaults のインスタンス

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        // FPS や時間などのデバッグ用統計情報の表示
        sceneView.showsStatistics = false
        // シーンの作成
        // let scene = SCNScene(named: "art.scnassets/clark.scn")!
        let scene = SCNScene()
        //特徴点とワールド原点の表示
        sceneView.debugOptions = [
            ARSCNDebugOptions.showFeaturePoints,
            // ARSCNDebugOptions.showWorldOrigin
        ]
        //光源の有効化
        sceneView.autoenablesDefaultLighting = true;
        // Set the scene to the view
        sceneView.scene = scene
        
        // ジェスチャーの追加
        let gesture = UITapGestureRecognizer(target: self, action:#selector(onTap))
        self.sceneView.addGestureRecognizer(gesture)
        
        
        // UserDefaults の処理
        userDefaults.register(defaults: ["cp_count": 0]) // クラークポイントの処理
        userDefaults.register(defaults: ["isGoldAnnounced": false])
        userDefaults.register(defaults: ["isGoldToggle": false])
        // Key を指定して User Defaults の読み込み
        cp_counter = userDefaults.object(forKey: "cp_count") as! Int
        isGoldAnnouncedFlag = userDefaults.object(forKey: "isGoldAnnounced") as! Bool
        isGoldFlag = userDefaults.object(forKey: "isGoldToggle") as! Bool
        
        cp_counter -= 1 // 起動時はラベルの更新前に -1 してカウント数を調整
        self.countupCP() // ラベルの更新処理および金色フラグの変更

        // 金色フラグの有無による処理
        if !(cp_counter > cp_limit) {
            gold_switch.setOn(false, animated: true)
            isGoldFlag = false
            // そもそも switch を表示させない
            gold_switch.isHidden = true
        } else {
            // switch を表示させる
            gold_switch.isHidden = false
            gold_switch.setOn(isGoldFlag, animated: true)
            isGoldAnnouncedFlag = true // 金色になることはお知らせ済み
        }

        // ライセンス表記にリンクを貼る処理
        license_textview.isUserInteractionEnabled = true
        let attributedString = NSMutableAttributedString(string: license_textview.text)
        attributedString.addAttribute(.link,
                                      value: "https://log.mkuriki.com/",
                                      range: NSString(string: license_textview.text).range(of: license_link))
        // 装飾をする文字列範囲を指定
        let range = (license_textview.text as NSString).range(of: license_link)
        // 指定文字列範囲に下線をひく
        attributedString.addAttribute(NSAttributedString.Key.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: range)
        // リンク色を白に設定
        license_textview.linkTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.white]
        license_textview.attributedText = attributedString
        license_textview.textAlignment = NSTextAlignment.center // 中央揃えに設定
        license_textview.backgroundColor = UIColor.clear // 背景色を透明に設定
        license_textview.textColor = UIColor.white // テキストカラーを白色に設定

        // isSelectableをtrue、isEditableをfalseにする必要がある
        // （isSelectableはデフォルトtrueだが説明のため記述）
        license_textview.isSelectable = true
        license_textview.isEditable = false
    }
    
    // ビュー表示時に呼ばれるメソッド
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        // 平面検出の有効化
        configuration.planeDetection = .horizontal
        // セッションの開始
        sceneView.session.run(configuration)
    }
    
    // ビュー非表示時に呼ばれるメソッド
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Pause the view's session
        sceneView.session.pause()
    }
    
    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
//
        return node
    }
*/
    
    // ARアンカー追加時に呼ばれるメソッド
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        DispatchQueue.main.async {
            
            // カメラの方向に正対するようにする
            if let camera = self.sceneView.pointOfView {
                node.eulerAngles.y = camera.eulerAngles.y  // カメラのオイラー角と同じにする
            }
            
            // ARAnchor の name が clark の時
            if anchor.name == "clark" {
                // モデルノードの追加
                let scene = SCNScene(named: "art.scnassets/clark.scn")
                let modelNode = (scene?.rootNode.childNode(withName: "clark", recursively: false))!

                // モデルのサイズ
                modelNode.scale = SCNVector3(0.200, 0.200, 0.200)
                node.addChildNode(modelNode)
            }
            
            // ARAnchor の name が clark_gold の時
            if anchor.name == "clark_gold" {
                // モデルノードの追加
                let scene = SCNScene(named: "art.scnassets/clark_gold.scn")
                let modelNode = (scene?.rootNode.childNode(withName: "clark", recursively: false))!

                // モデルのサイズ
                modelNode.scale = SCNVector3(0.200, 0.200, 0.200)
                node.addChildNode(modelNode)
            }
        }
    }
    
    // タップ時に呼ばれるメソッド
    @objc func onTap(sender: UITapGestureRecognizer) {
        // タップ位置の取得
        let location = sender.location(in: sceneView)

        // 平面 (plane) が洗濯されたかどうかのヒットテスト
        let planeHitTest = sceneView.hitTest(location, types: .existingPlaneUsingExtent)
        if !planeHitTest.isEmpty {
            
            // クラークポイントをカウントする 金色フラグもチェックする
            countupCP()
            
            // タップされたらバイブする
            // AudioServicesPlaySystemSound(SystemSoundID(1519)) // 短いバイブ
            AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate)) // 長いバイブ
            
            // 金色フラグによって読み込むモデル名を変える
            var modelName = "clark"
            if isGoldFlag {
                modelName = "clark_gold"
            }
            // ARアンカーの追加
            let anchor = ARAnchor(name:modelName, transform: planeHitTest.first!.worldTransform)
            sceneView.session.add(anchor: anchor)
            // AR アンカーが一度でも追加されたら説明表示ラベルを消す
            instruction_label.isHidden = true
        }
    }

    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
    }
    
    // シーンに追加したノードを削除する処理
    @IBAction func all_node_remove(_ sender: Any) {
        sceneView.scene.rootNode.enumerateChildNodes { (node, stop) in
        node.removeFromParentNode() }
    }
    
    // 金色スイッチの切り替え処理
    @IBAction func gold_change_switch(sender: UISwitch) {
        if( sender.isOn ) {
            isGoldFlag = true
        } else {
            isGoldFlag = false
        }
        // UserDefaults に保存
        userDefaults.set(isGoldFlag, forKey: "isGoldToggle")
    }
    
    // クラークポイントをカウントアップする関数
    func countupCP() {
        cp_counter += 1
        var countNum = String(format: "%02d", cp_counter)
        // ある数以上になったら表示桁数を変更する
        if cp_counter > cp_limit {
            countNum = String(format: "%05d", cp_counter)

            if !isGoldAnnouncedFlag {
                isGoldFlag = true
                // ダイアログの表示
                let dialog_title = NSLocalizedString("thank you for you playing", comment: "ありがとう")
                let dialog_content = NSLocalizedString("gold indicate", comment: "金クラーク説明")
                let gold_dialog = UIAlertController(title: dialog_title, message: dialog_content, preferredStyle: .alert)
                gold_dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
                self.present(gold_dialog, animated: true, completion: nil)
                isGoldAnnouncedFlag = true // 金色になることはお知らせ済み
                userDefaults.set(isGoldAnnouncedFlag, forKey: "isGoldAnnounced")
                
                // 金色切り替えボタンを表示させる
                gold_switch.isHidden = false
                gold_switch.setOn(true, animated: true)
                // UserDefaults に保存
                userDefaults.set(isGoldFlag, forKey: "isGoldToggle")
            }
        }
        // もし表示数が 5 桁を超えそうなら, さらに表示桁数を増やす
        if cp_counter > 99999 {
            countNum = String(format: "%08d", cp_counter)
        }
        // ラベルを更新
        cp_label.text = "Clark Level: " + countNum
        
        // クラークポイントを UserDefaults に保存
        userDefaults.set(cp_counter, forKey: "cp_count")
    }
    
    // 遊び方説明ダイアログの表示
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        let dialog_title = NSLocalizedString("how to play", comment: "あそびかた")
        let dialog_content = NSLocalizedString("how to play content", comment: "あそびかた説明")
        let how_to_dialog = UIAlertController(title: dialog_title, message: dialog_content, preferredStyle: .alert)
        how_to_dialog.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        // 生成したダイアログを表示
        self.present(how_to_dialog, animated: true, completion: nil)
    }
    
    /*
    // ライセンス表記をタップした時の動作
    @objc func tap_licenseLabelGesture(gestureRecognizer: UITapGestureRecognizer) {
        guard let text = license_label.text else { return }
        let touchPoint = gestureRecognizer.location(in: license_label)
        let textStorage = NSTextStorage(attributedString: NSAttributedString(string: license_link))
        let layoutManager = NSLayoutManager()
        textStorage.addLayoutManager(layoutManager)
        let textContainer = NSTextContainer(size: license_label.frame.size)
        layoutManager.addTextContainer(textContainer)
        textContainer.lineFragmentPadding = 0
        let toRange = (text as NSString).range(of: license_link)
        let glyphRange = layoutManager.glyphRange(forCharacterRange: toRange, actualCharacterRange: nil)
        let glyphRect = layoutManager.boundingRect(forGlyphRange: glyphRange, in: textContainer)
        if glyphRect.contains(touchPoint) {
            print("Tapped")
        }
    }
    */
}

// // 文字の表示
// // カメラの現在位置を取得する
// guard let camera = sceneView.pointOfView else { return }

// let textGeometry = SCNText(string: "水平面をタップしてください", extrusionDepth: 0.8)
// textGeometry.firstMaterial?.diffuse.contents = UIColor(named: "ArizarARFontColor")
// textGeometry.font = UIFont(name: "HiraginoSans-W6", size: 100)
// let textNode = SCNNode(geometry: textGeometry)
// let position = SCNVector3(0,0.1,-0.1)
//
// let billboardConstraint = SCNBillboardConstraint()
// //Y軸の回転はこの制約を加えない様にします。
// billboardConstraint.freeAxes = SCNBillboardAxis.Y
// textNode.constraints = [billboardConstraint]
//
// // カメラ位置からの偏差で求めた位置をノードの位置とする
// textNode.position = camera.convertPosition(position, to: nil)
// //カメラの向きに合わせる
// textNode.eulerAngles = camera.eulerAngles
//
// //大きさ設定
// textNode.scale = SCNVector3(0.0001,0.0001,0.001)

// sceneView.scene.rootNode.addChildNode(textNode)
