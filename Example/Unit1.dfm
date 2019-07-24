object frmTest: TfrmTest
  Left = 0
  Top = 0
  ClientHeight = 243
  ClientWidth = 527
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object btnTest: TButton
    Left = 8
    Top = 8
    Width = 75
    Height = 25
    Caption = 'btnTest'
    TabOrder = 0
    OnClick = btnTestClick
  end
  object Memo1: TMemo
    Left = 8
    Top = 39
    Width = 511
    Height = 196
    TabOrder = 1
  end
  object cbPos2Pos: TCheckBox
    Left = 97
    Top = 8
    Width = 160
    Height = 25
    Caption = 'cbPos2Pos'
    TabOrder = 2
  end
  object OpenDialog1: TOpenDialog
    Left = 448
    Top = 8
  end
end
