﻿{
  CRC32 (crc32b)
  speichersparend Variante da größere Dateien Blockweise verarbeitet werden.

  02/2013,xe2
  02/2016 XE10 x64 Test
  xx/xxxx FPC Ubuntu

  --------------------------------------------------------------------
  This Source Code Form is subject to the terms of the Mozilla Public
  License, v. 2.0. If a copy of the MPL was not distributed with this
  file, You can obtain one at https://mozilla.org/MPL/2.0/.

  THE SOFTWARE IS PROVIDED "AS IS" AND WITHOUT WARRANTY

  Last maintainer: Peter Lorenz
  You find the code useful? Donate!
  Paypal webmaster@peter-ebe.de
  --------------------------------------------------------------------

}

{$I ..\share_settings.inc}
unit checksum_unit;

interface

uses SysUtils, Classes;

{ ------------------------------------------------------------- }

type
  TCRC32 = class(TObject)
  private
    filebuffer: array [0 .. 1024 * 1024] of Byte;
    { früher 524288 } { belegt speicher (1x) }
    fstopgenerierung: boolean;
  public
    constructor create;
    destructor Destroy; override;

    { Prüfsummengenerierung über eine Datei }
    function GetCRC32(const FileName: string; var filecrc: longword): boolean;

    { Prüfsummengenerierung über eine Datei
      startoffset ist die Anzahl der am Start wegzulassenden Daten  (0=kein Offset, 10=die ersten 10 Bytes weglassen, usw.)
      stopoffset ist die Anzahl der am Ende wegzulassenden Daten    (0=bis Ende, 10=bis Dateigröße-10 Bytes)
    }
    function GetCRC32_pos2pos(const FileName: string; startoffset, endoffset: int64;
      var filecrc: longword): boolean;

    { falls Prüfsummengenerierung im Thread ausgeführt wird ist diese hiermit abbrechbar }
    procedure stopchecksumgenerierung;
  end;

  { ------------------------------------------------------------- }

implementation

constructor TCRC32.create;
begin
  inherited create;
  fstopgenerierung := false;
end;

destructor TCRC32.Destroy;
begin
  fstopgenerierung := true;
  inherited Destroy;
end;

{ -------------------------- Tabelle -------------------------- }

const
  crctable: array [0 .. 255] Of longword = ($00000000, $77073096, $EE0E612C,
    $990951BA, $076DC419, $706AF48F, $E963A535, $9E6495A3, $0EDB8832, $79DCB8A4,
    $E0D5E91E, $97D2D988, $09B64C2B, $7EB17CBD, $E7B82D07, $90BF1D91, $1DB71064,
    $6AB020F2, $F3B97148, $84BE41DE, $1ADAD47D, $6DDDE4EB, $F4D4B551, $83D385C7,
    $136C9856, $646BA8C0, $FD62F97A, $8A65C9EC, $14015C4F, $63066CD9, $FA0F3D63,
    $8D080DF5, $3B6E20C8, $4C69105E, $D56041E4, $A2677172, $3C03E4D1, $4B04D447,
    $D20D85FD, $A50AB56B, $35B5A8FA, $42B2986C, $DBBBC9D6, $ACBCF940, $32D86CE3,
    $45DF5C75, $DCD60DCF, $ABD13D59, $26D930AC, $51DE003A, $C8D75180, $BFD06116,
    $21B4F4B5, $56B3C423, $CFBA9599, $B8BDA50F, $2802B89E, $5F058808, $C60CD9B2,
    $B10BE924, $2F6F7C87, $58684C11, $C1611DAB, $B6662D3D, $76DC4190, $01DB7106,
    $98D220BC, $EFD5102A, $71B18589, $06B6B51F, $9FBFE4A5, $E8B8D433, $7807C9A2,
    $0F00F934, $9609A88E, $E10E9818, $7F6A0DBB, $086D3D2D, $91646C97, $E6635C01,
    $6B6B51F4, $1C6C6162, $856530D8, $F262004E, $6C0695ED, $1B01A57B, $8208F4C1,
    $F50FC457, $65B0D9C6, $12B7E950, $8BBEB8EA, $FCB9887C, $62DD1DDF, $15DA2D49,
    $8CD37CF3, $FBD44C65, $4DB26158, $3AB551CE, $A3BC0074, $D4BB30E2, $4ADFA541,
    $3DD895D7, $A4D1C46D, $D3D6F4FB, $4369E96A, $346ED9FC, $AD678846, $DA60B8D0,
    $44042D73, $33031DE5, $AA0A4C5F, $DD0D7CC9, $5005713C, $270241AA, $BE0B1010,
    $C90C2086, $5768B525, $206F85B3, $B966D409, $CE61E49F, $5EDEF90E, $29D9C998,
    $B0D09822, $C7D7A8B4, $59B33D17, $2EB40D81, $B7BD5C3B, $C0BA6CAD, $EDB88320,
    $9ABFB3B6, $03B6E20C, $74B1D29A, $EAD54739, $9DD277AF, $04DB2615, $73DC1683,
    $E3630B12, $94643B84, $0D6D6A3E, $7A6A5AA8, $E40ECF0B, $9309FF9D, $0A00AE27,
    $7D079EB1, $F00F9344, $8708A3D2, $1E01F268, $6906C2FE, $F762575D, $806567CB,
    $196C3671, $6E6B06E7, $FED41B76, $89D32BE0, $10DA7A5A, $67DD4ACC, $F9B9DF6F,
    $8EBEEFF9, $17B7BE43, $60B08ED5, $D6D6A3E8, $A1D1937E, $38D8C2C4, $4FDFF252,
    $D1BB67F1, $A6BC5767, $3FB506DD, $48B2364B, $D80D2BDA, $AF0A1B4C, $36034AF6,
    $41047A60, $DF60EFC3, $A867DF55, $316E8EEF, $4669BE79, $CB61B38C, $BC66831A,
    $256FD2A0, $5268E236, $CC0C7795, $BB0B4703, $220216B9, $5505262F, $C5BA3BBE,
    $B2BD0B28, $2BB45A92, $5CB36A04, $C2D7FFA7, $B5D0CF31, $2CD99E8B, $5BDEAE1D,
    $9B64C2B0, $EC63F226, $756AA39C, $026D930A, $9C0906A9, $EB0E363F, $72076785,
    $05005713, $95BF4A82, $E2B87A14, $7BB12BAE, $0CB61B38, $92D28E9B, $E5D5BE0D,
    $7CDCEFB7, $0BDBDF21, $86D3D2D4, $F1D4E242, $68DDB3F8, $1FDA836E, $81BE16CD,
    $F6B9265B, $6FB077E1, $18B74777, $88085AE6, $FF0F6A70, $66063BCA, $11010B5C,
    $8F659EFF, $F862AE69, $616BFFD3, $166CCF45, $A00AE278, $D70DD2EE, $4E048354,
    $3903B3C2, $A7672661, $D06016F7, $4969474D, $3E6E77DB, $AED16A4A, $D9D65ADC,
    $40DF0B66, $37D83BF0, $A9BCAE53, $DEBB9EC5, $47B2CF7F, $30B5FFE9, $BDBDF21C,
    $CABAC28A, $53B39330, $24B4A3A6, $BAD03605, $CDD70693, $54DE5729, $23D967BF,
    $B3667A2E, $C4614AB8, $5D681B02, $2A6F2B94, $B40BBE37, $C30C8EA1, $5A05DF1B,
    $2D02EF8D);

  { -------------------------- Tabellengenerierung -------------------------- }

  (*
    const CRCPOLY = $EDB88320;
    var CRCTable: array[0..512] Of longword;
    CRCTableok:boolean=false;

    procedure BuildCRCTable;
    var
    i, j: Word;
    r: longword;
    f:tex
    tfile;
    begin
    try
    assignfile(f, 'crctab.txt');
    rewrite(f);

    FillChar(CRCTable, SizeOf(CRCTable), 0);
    for i := 0 to 255 do
    begin
    r := i shl 1;
    for j := 8 downto 0 do
    begin
    if (r and 1) <> 0 then
    r := (r Shr 1) xor CRCPOLY
    else
    r := r shr 1;
    end; {next j}

    CRCTable[i] := r;
    writeln(f, '$'+inttohex(r, 8)+', ');
    end; {next i}
    crctableok:= true;

    closefile(f);
    except
    on e:exception do
    begin
    {nix}
    end;
    end;
    end;
  *)

  { -------------------------- Abbruchfunktion -------------------------- }

procedure TCRC32.stopchecksumgenerierung;
begin
  fstopgenerierung := true;
end;

{ -------------------------- CRC Berechnung -------------------------- }

function TCRC32.GetCRC32(const FileName: string; var filecrc: longword): boolean;

  function RecountCRC(b: Byte; CrcOld: longword): longword;
  begin
    Result := crctable[Byte(CrcOld xor longword(b))
      ] xor ((CrcOld shr 8) and $00FFFFFF)
  end;

var
  f: TFileStream;
  CRC: longword;
  i: longword;
  todo: longword;

  rest: int64;
begin
  Result := false;
  filecrc := 0;

  fstopgenerierung := false;
  f := nil;
  try
    CRC := $FFFFFFFF;

    f := TFileStream.create(FileName, fmOpenRead or fmShareDenyNone);
    rest := f.Size;
    if rest < 1 then
      raise exception.create('filesize 0');
    repeat
      if rest < sizeof(filebuffer) then
        todo := rest
      else
        todo := sizeof(filebuffer);
      rest := rest - todo;
      f.ReadBuffer(filebuffer, todo);

      for i := 0 to (todo - 1) do
        CRC := RecountCRC(filebuffer[i], CRC);
    until (rest <= 0) or (fstopgenerierung = true);
    CRC := Not CRC;

    filecrc := CRC;
    Result := true;
  except
    on e: exception do
    begin
      { nix, Rückgabe bleibt Fehlerhaft }
    end;
  end;
  try
    FreeAndNil(f);
  except
    on e: exception do
    begin
    end;
  end;
end;

{ -------------------------------------------------------------------- }

function TCRC32.GetCRC32_pos2pos(const FileName: string;
  startoffset, endoffset: int64; var filecrc: longword): boolean;

  function RecountCRC(b: Byte; CrcOld: longword): longword;
  begin
    Result := crctable[Byte(CrcOld xor longword(b))
      ] xor ((CrcOld shr 8) and $00FFFFFF)
  end;

var
  f: TFileStream;
  CRC: longword;
  i: longword;
  todo: longword;

  rest: int64;
begin
  Result := false;
  filecrc := 0;

  {
    startoffset: Anzahl der Daten die am Start weggelassen werden
    endoffset:   Anzahl der Daten die am Ende weggelassen werden
  }
  { aufgrund des datentypes immer > 0
    if startoffset < 0 then startoffset:= 0;
    if endoffset < 0 then endoffset:= 0; }

  fstopgenerierung := false;
  f := nil;
  try
    CRC := $FFFFFFFF;

    f := TFileStream.create(FileName, fmOpenRead or fmShareDenyNone);
    rest := f.Size;
    if rest < 1 then
      raise exception.create('filesize 0');

    { ggf. am Start wegzulassende Bytes lesen }
    if startoffset > 0 then
    begin
      f.Seek(startoffset, TSeekOrigin.soBeginning);
      rest := rest - startoffset;
    end;

    { ggf. am Ende wegzulassende Bytes abziehen }
    rest := rest - endoffset;

    { wenn noch etwas zu lesen ist CRC berechnen }
    if rest > 0 then
    begin
      repeat
        if rest < sizeof(filebuffer) then
          todo := rest
        else
          todo := sizeof(filebuffer);
        rest := rest - todo;
        f.ReadBuffer(filebuffer, todo);

        for i := 0 to (todo - 1) do
          CRC := RecountCRC(filebuffer[i], CRC);
      until (rest <= 0) or (fstopgenerierung = true);
      CRC := Not CRC;

      filecrc := CRC;
      Result := true;
    end;
  except
    on e: exception do
    begin
      { nix, Rückgabe bleibt Fehlerhaft }
    end;
  end;
  try
    FreeAndNil(f);
  except
    on e: exception do
    begin
    end;
  end;
end;

{ -------------------------------------------------------------------- }

end.
