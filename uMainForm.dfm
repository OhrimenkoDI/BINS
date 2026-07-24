object MainForm: TMainForm
  Left = 2
  Top = 94
  Caption = 'MainForm'
  ClientHeight = 979
  ClientWidth = 1542
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -19
  Font.Name = 'Courier New'
  Font.Style = [fsBold]
  OnCreate = FormCreate
  TextHeight = 22
  object Image1: TImage
    Left = 8
    Top = 40
    Width = 400
    Height = 400
  end
  object Image2: TImage
    Left = 414
    Top = 39
    Width = 400
    Height = 400
  end
  object Image3: TImage
    Left = 8
    Top = 445
    Width = 400
    Height = 400
  end
  object Image4: TImage
    Left = 414
    Top = 445
    Width = 400
    Height = 400
  end
  object QuatW: TLabel
    Left = 832
    Top = 39
    Width = 55
    Height = 22
    Caption = 'QuatW'
  end
  object QuatX: TLabel
    Left = 832
    Top = 62
    Width = 55
    Height = 22
    Caption = 'QuatX'
  end
  object QuatY: TLabel
    Left = 832
    Top = 90
    Width = 55
    Height = 22
    Caption = 'QuatY'
  end
  object QuatZ: TLabel
    Left = 832
    Top = 118
    Width = 55
    Height = 22
    Caption = 'QuatZ'
  end
  object Pitch: TLabel
    Left = 976
    Top = 39
    Width = 55
    Height = 22
    Caption = 'Pitch'
  end
  object Yaw: TLabel
    Left = 976
    Top = 90
    Width = 33
    Height = 22
    Caption = 'Yaw'
  end
  object Roll: TLabel
    Left = 976
    Top = 62
    Width = 44
    Height = 22
    Caption = 'Roll'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1542
    Height = 33
    Align = alTop
    TabOrder = 0
    object Button1: TButton
      Left = 1088
      Top = 5
      Width = 145
      Height = 25
      Caption = 'Copy Memo1'
      TabOrder = 0
      OnClick = Button1Click
    end
  end
  object Memo1: TMemo
    Left = 832
    Top = 160
    Width = 800
    Height = 740
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
  end
  object ScrollBar1: TScrollBar
    Left = 24
    Top = 936
    Width = 881
    Height = 17
    Max = 10
    PageSize = 0
    TabOrder = 2
    OnChange = ScrollBar1Change
  end
  object EdAz: TEdit
    Left = 24
    Top = 880
    Width = 121
    Height = 30
    TabOrder = 3
    Text = '0'
  end
  object edEl: TEdit
    Left = 168
    Top = 880
    Width = 121
    Height = 30
    TabOrder = 4
    Text = '0'
  end
  object BtSol: TButton
    Left = 333
    Top = 883
    Width = 75
    Height = 25
    Caption = 'BtSol'
    TabOrder = 5
    OnClick = BtSolClick
  end
  object ColorDialog1: TColorDialog
    Left = 1040
    Top = 128
  end
end
