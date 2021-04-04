#Powershellを初めて使う環境では以下のコマンドで実行ポリシーを変えておくこと。
#Set-ExecutionPolicy RemoteSigned

#このスプリクトの詳細は以下を参照のこと。
# https://docs.google.com/spreadsheets/d/1jVFoLsP_b0rwKRiIzmikmC-bRERwtlLbMQVTJ8qAp-I/edit#gid=1448018105

#処理する画像に余分な部分（ウインドウ枠等）が付いている場合、その幅を指定する。上、右、下、左の順にpxを正の数指定する。
$offset = @(31,1,1,1)

#ユーザー設定ここまで ===============================================


#ファイルをゴミ箱へ送る ここから ===============================================
#https://win.just4fun.biz/?PowerShell/%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%82%84%E3%83%95%E3%82%A9%E3%83%AB%E3%83%80%E3%82%92%E3%81%94%E3%81%BF%E7%AE%B1%E3%81%AB%E7%A7%BB%E5%8B%95%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95
Add-Type -AssemblyName Microsoft.VisualBasic
# フォルダをゴミ箱に移動する
function Folder-ToRecycleBin($target_dir_path) {
  if ((Test-Path $target_dir_path) -And ((Test-Path -PathType Container (Get-Item $target_dir_path)))) {
    $fullpath = (Get-Item $target_dir_path).FullName
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
  } else {
    Write-Output "'$target_dir_path' is not directory or not found."
  }
}
# ファイルをゴミ箱に移動する
function File-ToRecycleBin($target_file_path) {
  if ((Test-Path $target_file_path) -And ((Test-Path -PathType Leaf (Get-Item $target_file_path)))) {
    $fullpath = (Get-Item $target_file_path).FullName
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
  } else {
    Write-Output "'$target_file_path' is not file or not found."
  }
}
#ファイルをゴミ箱へ送る ここまで ===============================================

#画像をトリミングして保存する ここから ===============================================
# base: https://koyoshi50.com/powershell-trimming

# .NET Frameworkのアセンブリをロード
Add-Type -AssemblyName System.Drawing
function trimImage([String]$inputImageName, [Array]$cordinates, [String]$outputPrefix, [Array]$offset) {

    #current path
    $current_path = (Convert-Path .)

    #元画像読み込み(サポート形式:BMP、GIF、EXIF、JPG、PNG、TIFF)
    $SrcBmp = New-Object System.Drawing.Bitmap($current_path + "\" + $inputImageName)

    #オフセット部分を切り落としてゲーム画面の正確なサイズを取得
    $gameW = $SrcBmp.Width - $offset[1]  - $offset[3]
    $gameH = $SrcBmp.Height - $offset[0]  - $offset[2]

    #定義分だけループ処理
    foreach($i in $cordinates){
        #Rectangleに渡す座標を求める。$cordinates内の割合値とゲーム画面幅or高さの積を取り、四捨五入する。XYはさらに左上方向からのオフセットを加える。
        $tmpX = [Math]::Round($i[0] * $gameW, [MidpointRounding]::AwayFromZero) + $offset[3];
        $tmpY = [Math]::Round($i[1] * $gameH, [MidpointRounding]::AwayFromZero) + $offset[0];
        $tmpW = [Math]::Round($i[2] * $gameW, [MidpointRounding]::AwayFromZero)
        $tmpH = [Math]::Round($i[3] * $gameH, [MidpointRounding]::AwayFromZero)
        # トリミング画像作成
        $Rect = New-Object System.Drawing.Rectangle($tmpX, $tmpY, $tmpW, $tmpH)
        $DstBmp = $SrcBmp.Clone($Rect, $SrcBmp.PixelFormat)
        #画像保存
        $DstBmp.Save($current_path + "\out\" + $outputPrefix + $i[4], [System.Drawing.Imaging.ImageFormat]::Png)
        #オブジェクト破棄
        $DstBmp.Dispose()
    }

    # オブジェクト破棄
    $SrcBmp.Dispose()
}
#画像をトリミングして保存する ここまで ===============================================

#画像トリミング位置定義
#それぞれ (x座標, y座標, 幅, 高さ, 出力ファイル名)　だが、前４つはpx値ではなく元画像サイズに対する割合（100をかけない%値）で指定する。これにより多少精度が落ちるが、万が一解像度が異なった画像が来ても対応が出来る。
# ex: 70けもステのx座標0.54125 という値は 866(実測px) / 1600(元画像幅) = 0.54125 から来ている。この計算ではoffset（ウインドウ枠）の部分は考慮しない（切り出し時に処理する）
#注意：powershellでジャグ配列（配列の配列）を作る際は頭に,を置かないと展開されてしまうことがある。特に要素が1つの場合、,を忘れると1次元配列に展開されてしまう。
#　参考：https://tech.guitarrapc.com/entry/2015/09/05/012733#%E3%82%B8%E3%83%A3%E3%82%B0%E9%85%8D%E5%88%97%E5%86%85%E3%81%A7%E3%81%AE%E9%85%8D%E5%88%97%E7%B6%AD%E6%8C%81%E3%81%AB%E3%81%8C%E5%BF%85%E8%A6%81
$cordinates_f = @(
@(
    #f1s
    ,(0.54125, 0.4111111111, 0.115, 0.03888888889, "70けもステ.png")
    #,(0.643125, 0.4688888889, 0.0125, 0.03888888889, "野生解放.png")
    ,(0.54125, 0.5277777778, 0.115, 0.03888888889, "70体力.png")
    ,(0.54125, 0.5855555556, 0.115, 0.03888888889, "70攻撃.png")
    ,(0.54125, 0.6444444444, 0.115, 0.03888888889, "70守り.png")
    ,(0.54125, 0.7022222222, 0.095625, 0.03888888889, "回避.png")
    ,(0.54125, 0.7611111111, 0.115, 0.03888888889, "プラズム.png")
    ,(0.7325, 0.2488888889, 0.095625, 0.05333333333, "flag1.png")
    ,(0.7325, 0.3222222222, 0.095625, 0.05333333333, "flag2.png")
    ,(0.7325, 0.3955555556, 0.095625, 0.05333333333, "flag3.png")
    ,(0.7325, 0.4688888889, 0.095625, 0.05333333333, "flag4.png")
    ,(0.7325, 0.5433333333, 0.095625, 0.05333333333, "flag5.png")
    ,(0.76875, 0.6444444444, 0.076875, 0.03888888889, "Beat補正.png")
    ,(0.76875, 0.7, 0.076875, 0.03888888889, "Action補正.png")
    ,(0.76875, 0.7555555556, 0.076875, 0.03888888889, "Try補正.png")
),
@(
    #f1
    ,(0.54125, 0.3888888889, 0.115, 0.03888888889, "70けもステ.png")
    #,(0.643125, 0.4466666667, 0.0125, 0.03888888889, "野生解放.png")
    ,(0.54125, 0.5055555556, 0.115, 0.03888888889, "70体力.png")
    ,(0.54125, 0.5633333333, 0.115, 0.03888888889, "70攻撃.png")
    ,(0.54125, 0.6222222222, 0.115, 0.03888888889, "70守り.png")
    ,(0.54125, 0.68, 0.095625, 0.03888888889, "回避.png")
    ,(0.54125, 0.7388888889, 0.115, 0.03888888889, "プラズム.png")
    ,(0.7325, 0.2266666667, 0.095625, 0.05333333333, "flag1.png")
    ,(0.7325, 0.3, 0.095625, 0.05333333333, "flag2.png")
    ,(0.7325, 0.3733333333, 0.095625, 0.05333333333, "flag3.png")
    ,(0.7325, 0.4466666667, 0.095625, 0.05333333333, "flag4.png")
    ,(0.7325, 0.5211111111, 0.095625, 0.05333333333, "flag5.png")
    ,(0.76875, 0.6222222222, 0.076875, 0.03888888889, "Beat補正.png")
    ,(0.76875, 0.6777777778, 0.076875, 0.03888888889, "Action補正.png")
    ,(0.76875, 0.7333333333, 0.076875, 0.03888888889, "Try補正.png")
),
@(
    #f2
    ,(0.410625, 0.1544444444, 0.06375, 0.02888888889, "ミラクル+.png")
    ,(0.500625, 0.1844444444, 0.27875, 0.04222222222, "ミラクル名.png")
    ,(0.809375, 0.1844444444, 0.04, 0.04222222222, "MP.png")
    ,(0.4, 0.23, 0.4875, 0.1088888889, "ミラクルlv5.png")
    ,(0.500625, 0.3688888889, 0.38375, 0.04222222222, "とくいわざ名.png")
    ,(0.4, 0.4144444444, 0.4875, 0.1088888889, "とくいわざ詳細.png")
    ,(0.500625, 0.5533333333, 0.38375, 0.04222222222, "たいきスキル名.png")
    ,(0.4, 0.6, 0.4875, 0.1733333333, "たいきスキル詳細.png")
),
@(
    #f3
    ,(0.500625, 0.3288888889, 0.38375, 0.04222222222, "とくせい名.png")
    ,(0.4, 0.3744444444, 0.4875, 0.1733333333, "とくせい詳細.png")
    ,(0.500625, 0.5755555556, 0.2175, 0.04222222222, "キセキとくせい名.png")
    ,(0.4, 0.6266666667, 0.4875, 0.1711111111, "キセキとくせい詳細.png")
),
@(
    #f4
    ,(0.463125, 0.7644444444, 0.4425, 0.04222222222, "CV.png")
)
)

$cordinates_p = @(
@(
    #p1
    ,(0.071875, 0.07, 0.825625, 0.08888888889, "名前.png")
    ,(0.78375, 0.3722222222, 0.083125, 0.04222222222, "0体力.png")
    ,(0.78375, 0.43, 0.083125, 0.04222222222, "0攻撃.png")
    ,(0.78375, 0.4855555556, 0.083125, 0.04222222222, "0守り.png")
    ,(0.393125, 0.6055555556, 0.51, 0.2266666667, "とくせい(変化前).png")
),
@(
    #p2
    ,(0.393125, 0.6055555556, 0.51, 0.2266666667, "とくせい(変化後).png")
),
@(
    #p3
    ,(0.394375, 0.3666666667, 0.5075, 0.06555555556, "イラストレータ名.png")
)
)

#出力ディレクトリ(out)準備。現在のものをゴミ箱に入れ、新しく作る。
Folder-ToRecycleBin out
New-Item out -ItemType Directory | Out-Null

#1-5ループ（フレンズ、フォトともに一度に5つまで処理可とする。
for ($i=1; $i -lt 6; $i++){
    if(Test-Path ("f" + $i + "1s.png")){ trimImage ("f" + $i + "1s.png") $cordinates_f[0] ("f" + $i) $offset }
    for ($j=1; $j -lt 5; $j++){
    
        if(Test-Path ("f" + $i + "" + $j + ".png")){ trimImage ("f" + $i + "" + $j + ".png") $cordinates_f[$j] ("f" + $i) $offset }
    }
    "f" + $i + "処理完了。"

    if(Test-Path ("p" + $i + "1.png")){ trimImage ("p" + $i + "1.png") $cordinates_p[0] ("p" + $i) $offset }
    if(Test-Path ("p" + $i + "2.png")){ trimImage ("p" + $i + "2.png") $cordinates_p[1] ("p" + $i) $offset }
    if(Test-Path ("p" + $i + "3.png")){ trimImage ("p" + $i + "3.png") $cordinates_p[2] ("p" + $i) $offset }
    "p" + $i + "処理完了。"
}
