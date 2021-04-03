// base: http://www.initialsite.com/g07/16371
function ocr2() {
  const picFolderId = '1CrrGHJ9eq6LtiHTvby2uN1n1BiS2W6d_';  //作業フォルダ(OCR入力支援ツール 画像投入先)のid
  const folder = DriveApp.getFolderById(picFolderId);

  //作業シート取得
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("main");
  //作業シート内位置定義
  const friendsStartRow = 7; //フレンズ開始行
  const friendsEndRow = 40; //フレンズ終了行
  const photoStartRow = 44; //フォト開始行
  const photoEndRow = 54; //フォト終了行
  const startCol = 3; //入力欄開始列
  const headFriends = sheet.getRange(friendsStartRow,1,friendsEndRow - friendsStartRow + 1).getValues();  //フレンズ行名配列作成
  const headPhoto = sheet.getRange(photoStartRow,1,photoEndRow - photoStartRow + 1).getValues();  //フォト行名配列作成

  const startTime = Date.now(); //経過時間計測用

  let images = folder.getFilesByType('image/png');  //作業フォルダからpng画像のリストを取得  
  while(images.hasNext()){
    const image = images.next();
    const docName = image.getName().split("\.")[0];
    
    //作業ファイルをparentsで親ディレクトリを指定して保存。そうしないとルートに出来てしまう。 https://qiita.com/nazomikan/items/4fcf3bbd1b73162575f0
    var Request_body = {
      title: docName, 
      parents: [{id: picFolderId}],
      mimeType: 'image/jpeg'
    }
    Drive.Files.insert(Request_body, image, { ocr: true }); //OCRオプション付きで保存することにより画像がgoogle docとなる。

    //作成したgoogle docを取得する。driveの更新タイミングの問題か、docs.next();で取ろうとすると上手く取れない場合が結構ある。
    //そのため１秒のウェイトをいれつつ取得できるまでリトライを試みる。GASにはスクリプト実行時間制限があるので、最悪でもそこでループは終了する。
    let docs;
    do {
      Logger.log(docName + "読み取り待機(1s)");
      Utilities.sleep(1000);
      docs = folder.getFilesByType('application/vnd.google-apps.document');
    }while(!docs.hasNext());

    //google docからデータを取得
    let file = docs.next();
    let docId = file.getId();
    let doc = DocumentApp.openById(docId);
    let text = doc.getBody().getText().split('\n')[1]; //docファイルの2行目(index=1)を取得する。index=0は画像なので1から先を見る。

    //入力項目（ファイル名）に応じ、読み取ったtextを加工する
    //textが取得できなかった場合はskip
    if(text){
      //入力項目（ファイル名）取得
      const tmpFileName = docName.substr(2);
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
            text = "beat";
          }else if(text.substr(0,1) == 'A'){
            text = "action";
          }else if(text.substr(0,1) == 'T'){
            text = "try";
          }
        }

      }

      //データ投入処理
      let targetRow = -1;
      //ファイル名頭文字でフレンズかフォトかを判定し、入力項目名との一致を調べて編集対象行を特定する。
      if(docName.substr(0,1) == 'f'){
          targetRow = headFriends.findIndex(i => i[0] == tmpFileName);
          if(0 <= targetRow) targetRow += friendsStartRow;
      }else if(docName.substr(0,1) == 'p'){
          targetRow = headFriends.findIndex(i => i[0] == tmpFileName);
          if(0 <= targetRow) targetRow += photoStartRow;
      }
      //編集対象行が取得できた場合のみ処理
      if(0 < targetRow){
        const targetCol = docName.substr(1,1) *1 + startCol - 1; //ファイル名から編集対象列を計算。
        sheet.getRange(targetRow,targetCol).setValue(text);
      }else{
        Logger.log("targetRow取得失敗：" + targetRow);
      }

      const currentTime = Date.now() - startTime; //開始からの処理時間取得
      Logger.log("[" +  Math.floor(currentTime / 60000) + ":" +  ((currentTime % 60000) / 1000).toFixed(0) + "] " + docName + " 処理完了");
    }else{
      const currentTime = Date.now() - startTime; //開始からの処理時間取得
      Logger.log("[" +  Math.floor(currentTime / 60000) + ":" +  ((currentTime % 60000) / 1000).toFixed(0) + "] " + docName + " から有効なテキストが取得出来なかった為、処理をスキップ。");
    }

    //ファイル削除。setTrashed(true)でゴミ箱行きになる。
    image.setTrashed(true); //解析済画像
    //作業用doc。タイムアウト等で同名ファイルが複数存在する可能性があるので、ファイル名で検索して一致するものを全て削除する。
    docs = folder.getFilesByName(docName);
    while(docs.hasNext()){
      docs.next().setTrashed(true);
    }

  }

  Logger.log("全画像の処理完了。");
}

//作業シート初期化
function clearArea(){
  //シート取得
  var sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("main");

  //エリア初期化
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
 
}
