program TestFarsi10;

uses
  System.StartUpCopy,
  FMX.Forms,
  Unit3 in 'Unit3.pas' {Form3},
  PersianTool in 'PersianTool.pas',
  Unit4 in 'Unit4.pas' {Form4},
  FMX.TextLayout.GPU in 'FMX.TextLayout.GPU.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TForm3, Form3);
  Application.CreateForm(TForm4, Form4);
  Application.Run;
end.
