//
//  HelpViewController.swift
//  clark_statue
//
//  Created by Murahashi Kuriki on 2021/05/30.
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

class HelpViewController: UIViewController {

    @IBOutlet weak var helpTextView: UITextView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // let baseString = "これは設定アプリへのリンクを含む文章です。\n\nこちらのリンクはGoogle検索です"
        // let attributedString = NSMutableAttributedString(string: baseString)
        // 「北海道大学のクラーク像はオープンデータになりうるという話(https://log.mkuriki.com/opendata_clark_bust/)」
        let attributedString = NSMutableAttributedString(string: helpTextView.text)
        

        attributedString.addAttribute(.link,
                                      value: "https://log.mkuriki.com/opendata_clark_bust/",
                                      range: NSString(string: helpTextView.text).range(of: "北海道大学のクラーク像はオープンデータになりうるという話 - みんな重力のせい"))
        attributedString.addAttribute(.link,
                                      value: "https://log.mkuriki.com/opendata_clark_bust/",
                                      range: NSString(string: helpTextView.text).range(of: "Hokkaido University's statue of Clark could be open data"))

        helpTextView.attributedText = attributedString
        helpTextView.textColor = UIColor.label // テキストカラーをダークモードに合わせる

        // isSelectableをtrue、isEditableをfalseにする必要がある
        // （isSelectableはデフォルトtrueだが説明のため記述）
        helpTextView.isSelectable = true
        helpTextView.isEditable = false
        // helpTextView.delegate = self
    }
    
    func textView(_ textView: UITextView,
                  shouldInteractWith URL: URL,
                  in characterRange: NSRange,
                  interaction: UITextItemInteraction) -> Bool {

        UIApplication.shared.open(URL)

        return false
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
