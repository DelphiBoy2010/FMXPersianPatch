unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit;

type
  TForm3 = class(TForm)
    Edit3: TEdit;
    RadioButton1: TRadioButton;
    CheckBox1: TCheckBox;
    Label5: TLabel;
    Label4: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Button1: TButton;
    Edit2: TEdit;
    Edit1: TEdit;
    procedure Button1Click(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.fmx}

procedure TForm3.Button1Click(Sender: TObject);
begin
  Edit3.Text := 'تغییر متن';
  if (Sender is TEdit) then
  begin

  end;
end;

end.
