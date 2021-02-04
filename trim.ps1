#Powershell�����߂Ďg�����ł͈ȉ��̃R�}���h�Ŏ��s�|���V�[��ς��Ă������ƁB
#Set-ExecutionPolicy RemoteSigned

#���̃X�v���N�g�̏ڍׂ͈ȉ����Q�Ƃ̂��ƁB
# https://docs.google.com/spreadsheets/d/1jVFoLsP_b0rwKRiIzmikmC-bRERwtlLbMQVTJ8qAp-I/edit#gid=1448018105

#��������摜�ɗ]���ȕ����i�E�C���h�E�g���j���t���Ă���ꍇ�A���̕����w�肷��B��A�E�A���A���̏���px�𐳂̐��w�肷��B
$offset = @(31,1,1,1)

#���[�U�[�ݒ肱���܂� ===============================================


#�t�@�C�����S�~���֑��� �������� ===============================================
#https://win.just4fun.biz/?PowerShell/%E3%83%95%E3%82%A1%E3%82%A4%E3%83%AB%E3%82%84%E3%83%95%E3%82%A9%E3%83%AB%E3%83%80%E3%82%92%E3%81%94%E3%81%BF%E7%AE%B1%E3%81%AB%E7%A7%BB%E5%8B%95%E3%81%99%E3%82%8B%E6%96%B9%E6%B3%95
Add-Type -AssemblyName Microsoft.VisualBasic
# �t�H���_���S�~���Ɉړ�����
function Folder-ToRecycleBin($target_dir_path) {
  if ((Test-Path $target_dir_path) -And ((Test-Path -PathType Container (Get-Item $target_dir_path)))) {
    $fullpath = (Get-Item $target_dir_path).FullName
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
  } else {
    Write-Output "'$target_dir_path' is not directory or not found."
  }
}
# �t�@�C�����S�~���Ɉړ�����
function File-ToRecycleBin($target_file_path) {
  if ((Test-Path $target_file_path) -And ((Test-Path -PathType Leaf (Get-Item $target_file_path)))) {
    $fullpath = (Get-Item $target_file_path).FullName
    [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($fullpath,'OnlyErrorDialogs','SendToRecycleBin')
  } else {
    Write-Output "'$target_file_path' is not file or not found."
  }
}
#�t�@�C�����S�~���֑��� �����܂� ===============================================

#�摜���g���~���O���ĕۑ����� �������� ===============================================
# base: https://koyoshi50.com/powershell-trimming

# .NET Framework�̃A�Z���u�������[�h
Add-Type -AssemblyName System.Drawing
function trimImage([String]$inputImageName, [Array]$cordinates, [String]$outputPrefix, [Array]$offset) {

    #current path
    $current_path = (Convert-Path .)

    #���摜�ǂݍ���(�T�|�[�g�`��:BMP�AGIF�AEXIF�AJPG�APNG�ATIFF)
    $SrcBmp = New-Object System.Drawing.Bitmap($current_path + "\" + $inputImageName)

    #�I�t�Z�b�g������؂藎�Ƃ��ăQ�[����ʂ̐��m�ȃT�C�Y���擾
    $gameW = $SrcBmp.Width - $offset[1]  - $offset[3]
    $gameH = $SrcBmp.Height - $offset[0]  - $offset[2]

    #��`���������[�v����
    foreach($i in $cordinates){
        #Rectangle�ɓn�����W�����߂�B$cordinates���̊����l�ƃQ�[����ʕ�or�����̐ς����A�l�̌ܓ�����BXY�͂���ɍ����������̃I�t�Z�b�g��������B
        $tmpX = [Math]::Round($i[0] * $gameW, [MidpointRounding]::AwayFromZero) + $offset[3];
        $tmpY = [Math]::Round($i[1] * $gameH, [MidpointRounding]::AwayFromZero) + $offset[0];
        $tmpW = [Math]::Round($i[2] * $gameW, [MidpointRounding]::AwayFromZero)
        $tmpH = [Math]::Round($i[3] * $gameH, [MidpointRounding]::AwayFromZero)
        # �g���~���O�摜�쐬
        $Rect = New-Object System.Drawing.Rectangle($tmpX, $tmpY, $tmpW, $tmpH)
        $DstBmp = $SrcBmp.Clone($Rect, $SrcBmp.PixelFormat)
        #�摜�ۑ�
        $DstBmp.Save($current_path + "\out\" + $outputPrefix + $i[4], [System.Drawing.Imaging.ImageFormat]::Png)
        #�I�u�W�F�N�g�j��
        $DstBmp.Dispose()
    }

    # �I�u�W�F�N�g�j��
    $SrcBmp.Dispose()
}
#�摜���g���~���O���ĕۑ����� �����܂� ===============================================

#�摜�g���~���O�ʒu��`
#���ꂼ�� (x���W, y���W, ��, ����, �o�̓t�@�C����)�@�����A�O�S��px�l�ł͂Ȃ����摜�T�C�Y�ɑ΂��銄���i100�������Ȃ�%�l�j�Ŏw�肷��B����ɂ�葽�����x�������邪�A������𑜓x���قȂ����摜�����Ă��Ή����o����B
# ex: 70�����X�e��x���W0.54125 �Ƃ����l�� 866(����px) / 1600(���摜��) = 0.54125 ���痈�Ă���B���̌v�Z�ł�offset�i�E�C���h�E�g�j�̕����͍l�����Ȃ��i�؂�o�����ɏ�������j
#���ӁFpowershell�ŃW���O�z��i�z��̔z��j�����ۂ͓���,��u���Ȃ��ƓW�J����Ă��܂����Ƃ�����B���ɗv�f��1�̏ꍇ�A,��Y����1�����z��ɓW�J����Ă��܂��B
#�@�Q�l�Fhttps://tech.guitarrapc.com/entry/2015/09/05/012733#%E3%82%B8%E3%83%A3%E3%82%B0%E9%85%8D%E5%88%97%E5%86%85%E3%81%A7%E3%81%AE%E9%85%8D%E5%88%97%E7%B6%AD%E6%8C%81%E3%81%AB%E3%81%8C%E5%BF%85%E8%A6%81
$cordinates_f1s = @(
    ,(0.54125, 0.4111111111, 0.115, 0.03888888889, "70�����X�e.png")
    #,(0.643125, 0.4688888889, 0.0125, 0.03888888889, "�쐶���.png")
    ,(0.54125, 0.5277777778, 0.115, 0.03888888889, "70�̗�.png")
    ,(0.54125, 0.5855555556, 0.115, 0.03888888889, "70�U��.png")
    ,(0.54125, 0.6444444444, 0.115, 0.03888888889, "70���.png")
    ,(0.54125, 0.7022222222, 0.095625, 0.03888888889, "���.png")
    ,(0.54125, 0.7611111111, 0.115, 0.03888888889, "�v���Y��.png")
    ,(0.7325, 0.2488888889, 0.095625, 0.05333333333, "flag1.png")
    ,(0.7325, 0.3222222222, 0.095625, 0.05333333333, "flag2.png")
    ,(0.7325, 0.3955555556, 0.095625, 0.05333333333, "flag3.png")
    ,(0.7325, 0.4688888889, 0.095625, 0.05333333333, "flag4.png")
    ,(0.7325, 0.5433333333, 0.095625, 0.05333333333, "flag5.png")
    ,(0.76875, 0.6444444444, 0.076875, 0.03888888889, "Beat�␳.png")
    ,(0.76875, 0.7, 0.076875, 0.03888888889, "Action�␳.png")
    ,(0.76875, 0.7555555556, 0.076875, 0.03888888889, "Try�␳.png")
)
$cordinates_f1 = @(
    ,(0.54125, 0.3888888889, 0.115, 0.03888888889, "70�����X�e.png")
    #,(0.643125, 0.4466666667, 0.0125, 0.03888888889, "�쐶���.png")
    ,(0.54125, 0.5055555556, 0.115, 0.03888888889, "70�̗�.png")
    ,(0.54125, 0.5633333333, 0.115, 0.03888888889, "70�U��.png")
    ,(0.54125, 0.6222222222, 0.115, 0.03888888889, "70���.png")
    ,(0.54125, 0.68, 0.095625, 0.03888888889, "���.png")
    ,(0.54125, 0.7388888889, 0.115, 0.03888888889, "�v���Y��.png")
    ,(0.7325, 0.2266666667, 0.095625, 0.05333333333, "flag1.png")
    ,(0.7325, 0.3, 0.095625, 0.05333333333, "flag2.png")
    ,(0.7325, 0.3733333333, 0.095625, 0.05333333333, "flag3.png")
    ,(0.7325, 0.4466666667, 0.095625, 0.05333333333, "flag4.png")
    ,(0.7325, 0.5211111111, 0.095625, 0.05333333333, "flag5.png")
    ,(0.76875, 0.6222222222, 0.076875, 0.03888888889, "Beat�␳.png")
    ,(0.76875, 0.6777777778, 0.076875, 0.03888888889, "Action�␳.png")
    ,(0.76875, 0.7333333333, 0.076875, 0.03888888889, "Try�␳.png")
)
$cordinates_f2 = @(
    ,(0.410625, 0.1544444444, 0.06375, 0.02888888889, "�~���N��+.png")
    ,(0.500625, 0.1844444444, 0.27875, 0.04222222222, "�~���N����.png")
    ,(0.809375, 0.1844444444, 0.04, 0.04222222222, "MP.png")
    ,(0.4, 0.23, 0.4875, 0.1088888889, "�~���N��lv5.png")
    ,(0.500625, 0.3688888889, 0.38375, 0.04222222222, "�Ƃ����킴��.png")
    ,(0.4, 0.4144444444, 0.4875, 0.1088888889, "�Ƃ����킴�ڍ�.png")
    ,(0.500625, 0.5533333333, 0.38375, 0.04222222222, "�������X�L����.png")
    ,(0.4, 0.6, 0.4875, 0.1733333333, "�������X�L���ڍ�.png")
)
$cordinates_f3 = @(
    ,(0.500625, 0.3288888889, 0.38375, 0.04222222222, "�Ƃ�������.png")
    ,(0.4, 0.3744444444, 0.4875, 0.1733333333, "�Ƃ������ڍ�.png")
    ,(0.500625, 0.5755555556, 0.2175, 0.04222222222, "�L�Z�L�Ƃ�������.png")
    ,(0.4, 0.6266666667, 0.4875, 0.1711111111, "�L�Z�L�Ƃ������ڍ�.png")
)
$cordinates_f4 = @(
    ,(0.463125, 0.7644444444, 0.4425, 0.04222222222, "CV.png")
)
$cordinates_p1 = @(
    ,(0.071875, 0.07, 0.825625, 0.08888888889, "���O.png")
    ,(0.78375, 0.3722222222, 0.083125, 0.04222222222, "0�̗�.png")
    ,(0.78375, 0.43, 0.083125, 0.04222222222, "0�U��.png")
    ,(0.78375, 0.4855555556, 0.083125, 0.04222222222, "0���.png")
    ,(0.393125, 0.6055555556, 0.51, 0.2266666667, "�Ƃ�����(�ω��O).png")
)
$cordinates_p2 = @(
    ,(0.393125, 0.6055555556, 0.51, 0.2266666667, "�Ƃ�����(�ω���).png")
)
$cordinates_p3 = @(
    ,(0.394375, 0.3666666667, 0.5075, 0.06555555556, "�C���X�g���[�^��.png")
)

#�o�̓f�B���N�g��(out)�����B���݂̂��̂��S�~���ɓ���A�V�������B
Folder-ToRecycleBin out
New-Item out -ItemType Directory | Out-Null

#1-5���[�v�i�t�����Y�A�t�H�g�Ƃ��Ɉ�x��5�܂ŏ����Ƃ���B���ۂɂ�GAS�̏�������(6���ȓ�)�̓s���Ńt�����Y�Ȃ��x��2�l���炢�����E�B�j
for ($i=1; $i -lt 6; $i++){
    #�Ή�����t�����Y�摜�������Ă���ꍇ�͏���
    if(((Test-Path ("f" + $i + "1.png")) -or (Test-Path ("f" + $i + "1s.png"))) -and (Test-Path ("f" + $i + "2.png")) -and (Test-Path ("f" + $i + "3.png")) -and (Test-Path ("f" + $i + "4.png"))){
        "f" + $i + "1(s) �` 4.png�����o�B�����J�n�B"
        if(Test-Path ("f" + $i + "1s.png")){
            #1s.png(���U��ԉ摜�j������ꍇ�͂�����������B1.png�������ɂ����Ă���������B
            trimImage ("f" + $i + "1s.png") $cordinates_f1s ("f" + $i) $offset
        }else{
            #1s.png(���U��ԁj�������̂�1.png�������B
            trimImage ("f" + $i + "1.png") $cordinates_f1 ("f" + $i) $offset
        }
        trimImage ("f" + $i + "2.png") $cordinates_f2 ("f" + $i) $offset
        trimImage ("f" + $i + "3.png") $cordinates_f3 ("f" + $i) $offset
        trimImage ("f" + $i + "4.png") $cordinates_f4 ("f" + $i) $offset
        "���������B"

    }
    #�Ή�����t�H�g�摜�������Ă���ꍇ�͏���
    if((Test-Path ("p" + $i + "1.png")) -and (Test-Path ("p" + $i + "2.png")) -and (Test-Path ("p" + $i + "3.png"))){
        "p" + $i + "1 �` 3.png�����o�B�����J�n�B"
        trimImage ("p" + $i + "1.png") $cordinates_p1 ("p" + $i) $offset
        trimImage ("p" + $i + "2.png") $cordinates_p2 ("p" + $i) $offset
        trimImage ("p" + $i + "3.png") $cordinates_p3 ("p" + $i) $offset
        "���������B"
    }
}
