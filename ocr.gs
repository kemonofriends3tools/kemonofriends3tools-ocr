// base: http://www.initialsite.com/g07/16371
function ocr() {
  var picFolderId = 'xxxxxxxxxx';  //作業フォルダ(OCR入力支援ツール 画像投入先)のid
  var folder = DriveApp.getFolderById(picFolderId);
  var images = folder.getFilesByType('image/png');  //作業フォルダからpng画像のリストを取得  
  var dataMap = {}; //スプレッドシートに渡すデータを保持する連想配列

  const startTime = Date.now(); //経過時間計測
  
  while(images.hasNext()){
    var image = images.next();
    var docName = image.getName().split("\.")[0];
    
    //作業ファイルをparentsで親ディレクトリを指定して保存。そうしないとルートに出来てしまう。 https://qiita.com/nazomikan/items/4fcf3bbd1b73162575f0
    var Request_body = {
      title: "tmp_" + docName, 
      parents: [{id: picFolderId}],
      mimeType: 'image/jpeg'
    }
    Drive.Files.insert(Request_body, image, { ocr: true }); //OCRオプション付きで保存することにより画像がgoogle docとなる。

    var docs;
    do {
      Logger.log(docName + "読み取り待機(1s)");
      Utilities.sleep(1000); //driveのタイミングの問題か、docs.next();で取得エラーになることがあるのでここで１秒待ってみる。
      docs = folder.getFilesByType('application/vnd.google-apps.document');
    }while(!docs.hasNext());

    var file = docs.next();
    var docId = file.getId();
    var doc = DocumentApp.openById(docId);
    var text = doc.getBody().getText().split('\n')[1]; //作業用docファイルのn行目を取得する。0は画像なので1から先を見る。
    
    //入力項目（ファイル名）に応じ、読み取ったtextを加工する
    //textが取得できなかった場合はskip
    if(text){
      //入力項目（ファイル名）取得
      var tmpFileName = docName.substr(2);
      if(tmpFileName == "70けもステ" ||tmpFileName == "70体力" ||tmpFileName == "70攻撃" ||tmpFileName == "70守り" ||tmpFileName == "プラズム" ||tmpFileName == "MP"){
        //数値なので、数字以外は削除
        text = text.replace(/[^0-9]/g, '');
      }else if(tmpFileName == "回避" || tmpFileName == "Beat補正" ||tmpFileName == "Action補正" ||tmpFileName == "Try補正"){
        //小数点を含む数値なので、数字と小数点以外は削除。符号も消えるがマイナスは現時点で存在しないので除外。
        text = text.replace(/[^0-9\.]/g, '');
      }else if(tmpFileName == "flag1" ||tmpFileName == "flag2" ||tmpFileName == "flag3" ||tmpFileName == "flag4" ||tmpFileName == "flag5"){
        //flag関連。頭文字で変換。
        if(1 <= text.length){
          if(text.substr(0,1) == 'B'){
            text = "b"
          }else if(text.substr(0,1) == 'A'){
            //actionは最後2文字が数値ならそれを加える。
            var tmpActionValue = "";
            if(3<= text.length && !isNaN(text.substr(-2))){
                tmpActionValue = text.substr(-2);
            }
            text = "a" + tmpActionValue;
          }else if(text.substr(0,1) == 'T'){
            text = "t"
          }
        }
      }else if(tmpFileName == "ミラクル+"){
        if(1 <= text.length){
          if(text.substr(0,1) == 'B'){
            text = "beat"
          }else if(text.substr(0,1) == 'A'){
            text = "action";
          }else if(text.substr(0,1) == 'T'){
            text = "try"
          }
        }

      }
    }

    //取得したデータをdataMapに格納する。
    //typeに対応するオブジェクトの存在を確認し、無い場合は作る。
    if(!dataMap[docName.substr(0,1)]) dataMap[docName.substr(0,1)] = {};
    //typeオブジェクト取得
    var tmpObjType = dataMap[docName.substr(0,1)];
    //loopCount（ループ回数）に対応するオブジェクトの存在を確認し、無い場合は作る。
    if(!tmpObjType[docName.substr(1,1)]) tmpObjType[docName.substr(1,1)] = {};
    //loopCount（ループ回数）オブジェクト取得
    var tmpObjLoopCount = tmpObjType[docName.substr(1,1)];
    //データ投入。キーはファイル名の残り（列名に等しいはず）
    tmpObjLoopCount[docName.substr(2)] = text;

    const currentTime = Date.now() - startTime; //開始からの処理時間取得
    Logger.log("[" +  Math.floor(currentTime / 60000) + ":" +  ((currentTime % 60000) / 1000).toFixed(0) + "] " + docName + " 読み取り処理完了");

    //ファイル削除。setTrashed(true)でゴミ箱行きになる。
    file.setTrashed(true);  //作業用doc
    image.setTrashed(true); //解析済画像
  }

  //作業ディレクトリを空にする
  var files = folder.getFiles();
  while(files.hasNext()) {
    var file = files.next();
    file.setTrashed(true);
  }
  
  Logger.log("全画像の読み取り処理完了。シートへのデータ投入処理開始。");

  //作業シート取得
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("main");

  var friendsStartRow = 11; //フレンズ開始行
  var friendsEndRow = 38; //フレンズ終了行（備考等OCRに存在しないものは含まない）
  var photoStartRow = 44; //フォト開始行
  var photoEndRow = 52; //フォト終了行（備考等OCRに存在しないものは含まない）

  //作業エリア初期化
  sheet.getRange(7,3,34,5).clearContent();
  sheet.getRange(44,3,11,5).clearContent();

  //初期けも級、野生解放に初期値投入
  sheet.getRange(9,3,1,5).setValue(4);
  sheet.getRange(12,3,1,5).setValue(4);

  //実装日投入
  var today = new Date();
  today.setHours(0, 0, 0, 0);
  sheet.getRange(39,3,1,5).setValue(today);
  sheet.getRange(53,3,1,5).setValue(today);

  if(dataMap['f']){
    //フレンズ有
    var tmpObjType = dataMap['f'];
    for(var i=1; i<=5; i++){
      if(tmpObjType[i]){
        //loopCount（ループ回数）オブジェクト有
        var tmpObj = tmpObjType[i];

        //フレンズの項目でループ（野生解放～CV）
        for(var j=friendsStartRow; j<=friendsEndRow; j++){
          //1列目の項目名取得
          var tmpHead = sheet.getRange(j,1).getValues();
          //対応する場所に書き込み(注：iは1スタート)
          sheet.getRange(j,2 + i).setValue(tmpObj[tmpHead])
        }
      }
    }
  }

  if(dataMap['p']){
    //フォト有
    var tmpObjType = dataMap['p'];
    for(var i=1; i<=5; i++){
      if(tmpObjType[i]){
        //loopCount（ループ回数）オブジェクト有
        var tmpObj = tmpObjType[i];

        //フォトの項目でループ（野生解放～CV）
        for(var j=photoStartRow; j<=photoEndRow; j++){
          //1列目の項目名取得
          var tmpHead = sheet.getRange(j,1).getValues();
          //対応する場所に書き込み(注：iは1スタート)
          sheet.getRange(j,2 + i).setValue(tmpObj[tmpHead])
        }
      }
    }
  }

}