unit Unit3;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Edit, FMX.ListBox, FMX.Layouts,
  FMX.ListView.Types, FMX.ListView.Appearances, FMX.ListView.Adapters.Base,
  FMX.ListView;

type
  TForm3 = class(TForm)
    Button1: TButton;
    Edit3: TEdit;
    RadioButton1: TRadioButton;
    CheckBox1: TCheckBox;
    Label5: TLabel;
    Label4: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Edit2: TEdit;
    Edit1: TEdit;
    ListBox1: TListBox;
    ComboBox1: TComboBox;
    Edit4: TEdit;
    Edit5: TEdit;
    StyleBook1: TStyleBook;
    ListView1: TListView;
    Button2: TButton;
    Button3: TButton;
    Edit6: TEdit;
    Label6: TLabel;
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  Form3: TForm3;

implementation

{$R *.fmx}

uses PersianTool, System.StrUtils;

procedure TForm3.Button1Click(Sender: TObject);
begin
  TFarsi.Convert('سلام خوبی')
  //Edit3.Text := 'سامانه نمایشگر مخزن';
  //ListBox1.Items.Add('قرمز');
  //ShowMessage('Hello');
  //Edit1.Text := 'خوبی';
end;

procedure TForm3.FormCreate(Sender: TObject);
begin
  //Edit1.Text := ReverseString('ali');
end;

procedure TForm3.FormShow(Sender: TObject);
begin
 // ListBox1.Items.Add('سلام');
 // ListBox1.Items.Add('خوبی');
end;

end.
