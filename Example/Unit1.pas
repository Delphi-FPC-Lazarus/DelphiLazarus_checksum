unit Unit1;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls;

type
  TfrmTest = class(TForm)
    btnTest: TButton;
    OpenDialog1: TOpenDialog;
    Memo1: TMemo;
    cbPos2Pos: TCheckBox;
    procedure btnTestClick(Sender: TObject);
  private
    { Private-Deklarationen }
  public
    { Public-Deklarationen }
  end;

var
  frmTest: TfrmTest;

implementation

{$R *.dfm}

uses checksum_unit;

procedure TfrmTest.btnTestClick(Sender: TObject);
var crcobj:TCrc32;
    crc:longword;
    start,stop:TDateTime;
begin
 if not OpenDialog1.Execute then exit;

 try
   crcobj:= TCrc32.Create;
   start:= date+time;
   if cbPos2Pos.Checked then
   begin
    if not crcobj.GetCRC32_pos2pos(OpenDialog1.FileName, 1024, 0, crc) then raise exception.Create('Fehler');
   end
   else
   begin
    if not crcobj.GetCRC32(opendialog1.FileName, crc) then raise exception.Create('Fehler');
   end;

   stop:= date+time;
   memo1.Lines.Add(
      inttohex(crc,4) + ' => ' + format('%1.3f', [(stop-start)*24*3600])
                  );
 finally
  FreeAndNil(crcobj);
 end;

end;

end.
