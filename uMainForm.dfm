object MainForm: TMainForm
  Left = 2
  Top = 94
  Caption = 'MainForm'
  ClientHeight = 986
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
    Top = 446
    Width = 400
    Height = 400
  end
  object Image4: TImage
    Left = 414
    Top = 445
    Width = 400
    Height = 400
  end
  object WAccFiltr0: TLabel
    Left = 928
    Top = 680
    Width = 110
    Height = 22
    Caption = 'WAccFiltr0'
    Visible = False
  end
  object WAccFiltr1: TLabel
    Left = 928
    Top = 704
    Width = 110
    Height = 22
    Caption = 'WAccFiltr1'
    Visible = False
  end
  object WAccFiltr2: TLabel
    Left = 928
    Top = 728
    Width = 110
    Height = 22
    Caption = 'WAccFiltr2'
    Visible = False
  end
  object GyroZeroFiltr0: TLabel
    Left = 1000
    Top = 130
    Width = 154
    Height = 22
    Caption = 'GyroZeroFiltr0'
  end
  object GyroZeroFiltr1: TLabel
    Left = 1000
    Top = 155
    Width = 154
    Height = 22
    Caption = 'GyroZeroFiltr1'
  end
  object GyroZeroFiltr2: TLabel
    Left = 1000
    Top = 180
    Width = 154
    Height = 22
    Caption = 'GyroZeroFiltr2'
  end
  object pind1: TLabel
    Left = 928
    Top = 800
    Width = 55
    Height = 22
    Caption = 'pind1'
    Visible = False
  end
  object pind2: TLabel
    Left = 928
    Top = 824
    Width = 55
    Height = 22
    Caption = 'pind2'
    Visible = False
  end
  object pind0: TLabel
    Left = 928
    Top = 776
    Width = 55
    Height = 22
    Caption = 'pind0'
    Visible = False
  end
  object OXl2: TLabel
    Left = 1128
    Top = 488
    Width = 44
    Height = 22
    Caption = 'OXl2'
  end
  object OYl2: TLabel
    Left = 1128
    Top = 512
    Width = 44
    Height = 22
    Caption = 'OYl2'
    Visible = False
  end
  object OZl0: TLabel
    Left = 1128
    Top = 536
    Width = 44
    Height = 22
    Caption = 'OZl0'
    Visible = False
  end
  object OZl1: TLabel
    Left = 1128
    Top = 560
    Width = 44
    Height = 22
    Caption = 'OZl1'
    Visible = False
  end
  object AccFiltr0: TLabel
    Left = 1000
    Top = 40
    Width = 99
    Height = 22
    Caption = 'AccFiltr0'
  end
  object AccFiltr1: TLabel
    Left = 1000
    Top = 65
    Width = 99
    Height = 22
    Caption = 'AccFiltr1'
  end
  object AccFiltr2: TLabel
    Left = 1000
    Top = 90
    Width = 99
    Height = 22
    Caption = 'AccFiltr2'
  end
  object iACC0: TLabel
    Left = 832
    Top = 40
    Width = 55
    Height = 22
    Caption = 'iGir0'
  end
  object iACC1: TLabel
    Left = 832
    Top = 65
    Width = 55
    Height = 22
    Caption = 'iACC1'
  end
  object iACC2: TLabel
    Left = 832
    Top = 90
    Width = 55
    Height = 22
    Caption = 'iACC2'
  end
  object iGir0: TLabel
    Left = 832
    Top = 130
    Width = 55
    Height = 22
    Caption = 'iGir0'
  end
  object iGir1: TLabel
    Left = 832
    Top = 155
    Width = 55
    Height = 22
    Caption = 'iGir1'
  end
  object iGir2: TLabel
    Left = 832
    Top = 180
    Width = 55
    Height = 22
    Caption = 'iGir2'
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 1542
    Height = 33
    Align = alTop
    TabOrder = 0
    object BtOpenPort: TButton
      Left = 146
      Top = 5
      Width = 80
      Height = 25
      Caption = 'Open'
      TabOrder = 0
      OnClick = BtOpenPortClick
    end
    object BtClosePort: TButton
      Left = 232
      Top = 5
      Width = 80
      Height = 25
      Caption = 'Close'
      TabOrder = 1
      OnClick = BtClosePortClick
    end
    object ComboCOM: TComboBox
      Left = 8
      Top = 7
      Width = 121
      Height = 30
      TabOrder = 2
      Text = 'ComboCOM'
    end
  end
  object Memo1: TMemo
    Left = 833
    Top = 232
    Width = 409
    Height = 137
    Lines.Strings = (
      'Memo1')
    TabOrder = 1
  end
  object Memo2: TMemo
    Left = 1188
    Top = 457
    Width = 409
    Height = 389
    Lines.Strings = (
      'Memo1')
    TabOrder = 2
  end
  object TrackBar1: TTrackBar
    Left = 833
    Top = 391
    Width = 405
    Height = 45
    LineSize = 10
    Max = 100
    PageSize = 10
    Frequency = 5
    TabOrder = 3
    OnChange = TrackBar1Change
  end
end
