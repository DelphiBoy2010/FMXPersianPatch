unit PersianTool;

interface

uses System.Classes, System.Math;

type
  TStruc = class sealed(TObject)
  public
    Character, EndGlyph, IniGlyph, MidGlyph, IsoGlyph: Char;
    constructor Create(ACharacter, AEndGlyph, AIniGlyph, AMidGlyph,
      AIsoGlyph: Char);
  end;

  TFarsi = class sealed(TObject)
  strict private
  const
    N_DISTINCT_CHARACTERS = 43;
    class var SzLamAndAlef: String;
    class var SzLamStickAndAlef: String;
    class var SzLa: String;
    class var SzLaStick: String;
    class var SzLamAndAlefWoosim: String;
    class var SzLamStickAndAlefWoosim: String;
    class var SzLaWoosim: String;
    class var SzLaStickWoosim: String;
    class var ArrStruc: array of TStruc;
    class var ArrStrucWoosim: array of TStruc;
    class var IsFarsiConversionNeeded: Boolean;


    class function FarsiReverse(S: String): String;
    class function IsFromTheSet1(Ch: Char): Boolean;
    class function IsFromTheSet2(Ch: Char): Boolean;
    class function CharIsLTR(Ch: Char): Boolean;
    class function CharIsRTL(Ch: Char): Boolean;
    class function ReorderWords(S: String): String;
    class function ConvertWord(S: String): String;
  public
    class function Convert(S: String): String;
    class function ConvertBackToRealFarsi(S: String): String;
    class constructor Create;
    class function ReverseWords(S: string): string;
    class function ConvertWord2(S: String): String;
    class function IsFarsiChar(Ch: Char): Boolean;
    class function IsSpecialChar(Ch: Char): Boolean;
  end;

implementation

uses
  System.StrUtils, System.SysUtils, System.Character;

{ TStruc }

constructor TStruc.Create(ACharacter, AEndGlyph, AIniGlyph, AMidGlyph,
  AIsoGlyph: Char);
begin
  Character := ACharacter;
  EndGlyph := AEndGlyph;
  IniGlyph := AIniGlyph;
  MidGlyph := AMidGlyph;
  IsoGlyph := AIsoGlyph;
end;

{ TFarsi }

class function TFarsi.FarsiReverse(S: String): String;
var
  LRev: String;
  I: Integer;
begin
  Result := EmptyStr;
  LRev := EmptyStr;

  S := ReverseString(S);

  I := 0;
  while (I < S.Length) do
  begin
    if S.Chars[I].IsDigit then
    begin
      LRev := EmptyStr;
      while (I < S.Length) and (S.Chars[I].IsDigit or (S.Chars[I] = '/') or
        (S.Chars[I] = '.')) do
      begin
        LRev := LRev + S.Chars[I];
        Inc(I);
      end;

      LRev := ReverseString(LRev);
      Result := Result + LRev;
    end
    else
    begin
      Result := Result + S.Chars[I];
      Inc(I);
    end;
  end;
end;

class function TFarsi.CharIsLTR(Ch: Char): Boolean;
begin
  Result := ((Ch >= Char(65)) and (Ch <= Char(122))) or Ch.IsDigit;
end;

class function TFarsi.CharIsRTL(Ch: Char): Boolean;
begin
  Result := (Ch >= Char($0621)) or (Ch = Char($060C)) // ¡
    or (Ch = Char($061B)) // º
    or (Ch = Char($061F)) // ¿
    or ((Ch >= Char($0021)) and (Ch <= Char($002F))) or
    ((Ch >= Char($003A)) and (Ch <= Char($003F))) or (Ch = Char($005B)) or
    (Ch = Char($005D)) or (Ch = Char($007B)) or (Ch = Char($007D));
end;

class function TFarsi.ReorderWords(S: String): String;
const
  ST_RTL = 0;
  ST_LTR = 1;
var
  LPrevWord: String;
  LState, LPreState, I: Integer;
begin
  Result := EmptyStr;
  LPrevWord := EmptyStr;
  LState := ST_RTL;
  LPreState := ST_RTL;

  I := 0;
  while (I < S.Length) do
  begin
    if CharIsLTR(S.Chars[I]) and (LState <> ST_LTR) then
    begin
      // State changed to LTR
      LPreState := ST_RTL;
      LState := ST_LTR;
      Result := Result + LPrevWord;
      LPrevWord := S.Chars[I];
    end
    else if CharIsRTL(S.Chars[I]) and (LState <> ST_RTL) then
    begin
      // State changed to RTL
      LPreState := ST_LTR;
      LState := ST_RTL;
      Result := LPrevWord + Result;
      LPrevWord := S.Chars[I];
    end
    else
    // State is not changed
    begin
      case LState of
        ST_RTL:
          LPrevWord := S.Chars[I] + LPrevWord;
        ST_LTR:
          LPrevWord := LPrevWord + S.Chars[I];
      end;
      // LPrevWord:= LPrevWord + S.Chars[I];
    end;

    Inc(I);
  end;

  // Result:= LPrevWord + Result;

  case LPreState of
    ST_RTL:
      Result := LPrevWord + Result;
    ST_LTR:
      Result := Result + LPrevWord;
  end;

end;

class function TFarsi.ReverseWords(S: string): string;
const
  SpaceChar = ' ';
  //SpaceChar = Char($20)
var
  LArrWords: TArray<String>;
  I: Integer;
  st: string;
begin
  Result := EmptyStr;
  LArrWords := S.Split([SpaceChar]);
  for I := Low(LArrWords) to High(LArrWords) do
  begin
    st := LArrWords[I];
    if (st <> '') and (IsFarsiChar(st[1])) then
    begin
      LArrWords[I] := ReverseString(LArrWords[I]);
      Result := LArrWords[I] + SpaceChar + Result;
    end
    else
    begin
      Result := Result + SpaceChar + LArrWords[I];
    end;
  end;
end;

class function TFarsi.ConvertWord(S: String): String;
var
  LLinkBefore, LLinkAfter: Boolean;
  LIdx, I: Integer;
  LChr: Char;

begin
  Result := DupeString(' ', S.Length);
  LLinkBefore := False;
  LLinkAfter := False;
  I := 0;
  LIdx := 0;

  if (not TFarsi.IsFarsiConversionNeeded) or (S.IsEmpty) then
    Exit(S);

  while (I < S.Length) do
  begin
    if IsFarsiChar(S.Chars[I]) then
    begin
      LIdx := 0;
      LChr := #0;

      while (LIdx < N_DISTINCT_CHARACTERS) do
      begin
        if ArrStruc[LIdx].Character = S.Chars[I] then
          Break;

        Inc(LIdx);
      end;

      if (I = S.Length - 1) then
        LLinkAfter := False
      else
        LLinkAfter := IsFromTheSet1(S.Chars[I + 1]) or
          IsFromTheSet2(S.Chars[I + 1]);

      if I = 0 then
        LLinkBefore := False
      else
        LLinkBefore := IsFromTheSet1(S.Chars[I - 1]);

      if (LIdx < N_DISTINCT_CHARACTERS) then
      begin
        if LLinkBefore and LLinkAfter then
          LChr := ArrStruc[LIdx].MidGlyph
        else if LLinkBefore and not LLinkAfter then
          LChr := ArrStruc[LIdx].EndGlyph
        else if not LLinkBefore and LLinkAfter then
          LChr := ArrStruc[LIdx].IniGlyph
        else if not LLinkBefore and not LLinkAfter then
          LChr := ArrStruc[LIdx].IsoGlyph;
      end
      else
        LChr := S.Chars[I];

      Result[I] := LChr;
    end
    else
      Result[I] := S.Chars[I];

    Inc(I);
  end;

  //Result := Result.Replace(Char($200C), ' '); // Change NO SPACE to SPACE
  Result := Result.Replace(SzLamAndAlef, SzLa);
  // Join 'Lam' and 'Alef' and make 'La'
  Result := Result.Replace(SzLamStickAndAlef, SzLaStick);
  // Join 'Lam Stick' and 'Alef' and make 'La Stick'
  Result := ReorderWords(Result);
end;

class function TFarsi.ConvertWord2(S: String): String;
var
  LLinkBefore, LLinkAfter: Boolean;
  LIdx, I: Integer;
  LChr: Char;
begin
  Result := DupeString(' ', S.Length);
  LLinkBefore := False;
  LLinkAfter := False;
  I := 0;
  LIdx := 0;

  if (S.IsEmpty) then
    Exit(S);

  while (I < S.Length) do
  begin
    if IsFarsiChar(S.Chars[I]) then
    begin
      LIdx := 0;
      LChr := #0;

      while (LIdx < N_DISTINCT_CHARACTERS) do
      begin
        if ArrStruc[LIdx].Character = S.Chars[I] then
          Break;

        Inc(LIdx);
      end;

      if (I = S.Length - 1) then
        LLinkAfter := False
      else
        LLinkAfter := IsFromTheSet1(S.Chars[I + 1]) or
          IsFromTheSet2(S.Chars[I + 1]);

      if I = 0 then
        LLinkBefore := False
      else
        LLinkBefore := IsFromTheSet1(S.Chars[I - 1]);

      if (LIdx < N_DISTINCT_CHARACTERS) then
      begin
        if LLinkBefore and LLinkAfter then
          LChr := ArrStruc[LIdx].MidGlyph
        else if LLinkBefore and not LLinkAfter then
          LChr := ArrStruc[LIdx].EndGlyph
        else if not LLinkBefore and LLinkAfter then
          LChr := ArrStruc[LIdx].IniGlyph
        else if not LLinkBefore and not LLinkAfter then
          LChr := ArrStruc[LIdx].IsoGlyph;
      end
      else
        LChr := S.Chars[I];

      Result[I] := LChr;
    end
    else
      Result[I] := S.Chars[I];

    Inc(I);
  end;

  //Result := Result.Replace(Char($200C), ' '); // Change NO SPACE to SPACE
  Result := Result.Replace(SzLamAndAlef, SzLa);
  // Join 'Lam' and 'Alef' and make 'La'
  Result := Result.Replace(SzLamStickAndAlef, SzLaStick);
  // Join 'Lam Stick' and 'Alef' and make 'La Stick'
end;

class function TFarsi.Convert(S: String): String;
var
  LArrWords: TArray<String>;
  I: Integer;
  st: string;
begin
  // Result:= ConvertWord(S);

  Result := EmptyStr;
  LArrWords := S.Split([' ']);
  for I := Low(LArrWords) to High(LArrWords) do
  begin
    st := LArrWords[I];
    LArrWords[I] := ConvertWord(LArrWords[I]);
    if (st <> '') and (IsFarsiChar(st[1])) then
    begin
      Result := LArrWords[I] + ' ' + Result;
    end
    else
    begin
      Result := Result + ' ' + LArrWords[I];
    end;
  end;

end;

class function TFarsi.ConvertBackToRealFarsi(S: String): String;
var
  LSB: TStringBuilder;
  I, J: Integer;
  LFound: Boolean;
begin
  Result := EmptyStr;
  I := 0;
  J := 0;

  if not IsFarsiConversionNeeded then
    Exit(S);

  LSB := TStringBuilder.Create(EmptyStr);
  try
    while (I < S.Length) do
    begin
      LFound := False;
      for J := Low(ArrStruc) to High(ArrStruc) do
      begin
        if (S.Chars[I] = ArrStruc[J].MidGlyph) or
          (S.Chars[I] = ArrStruc[J].IniGlyph) or
          (S.Chars[I] = ArrStruc[J].EndGlyph) or
          (S.Chars[I] = ArrStruc[J].IsoGlyph) then
        begin
          LSB.Append(ArrStruc[J].Character);
          LFound := True;
          Break;
        end;
      end;

      if not LFound then
        LSB.Append(S.Chars[I]);

      Inc(I);
    end;

    Result := LSB.ToString;
    Result := Result.Replace(TFarsi.SzLa, 'áÇ');
    Result := Result.Replace(TFarsi.SzLaStick, 'áÇ');
    // Result:= TFarsi.ReorderWords(Result);
  finally
    FreeAndNil(LSB);
  end;
end;

class constructor TFarsi.Create;
var
  a: TStruc;
begin
  TFarsi.IsFarsiConversionNeeded := True;
  TFarsi.SzLamAndAlef := Char($FEDF) + Char($FE8E); // Lam + Alef
  TFarsi.SzLamStickAndAlef := Char($FEE0) + Char($FE8E); // Lam (Sticky !!!)+
  TFarsi.SzLa := Char($FEFB); // La
  TFarsi.SzLaStick := Char($FEFC); // La (Sticky!!!)
  TFarsi.SzLamAndAlefWoosim := Char($E1) + Char($BB); // Lam + Alef
  TFarsi.SzLamStickAndAlefWoosim := Char($90) + Char($BB);
  // Lam (Sticky !!!)+ Alef
  TFarsi.SzLaWoosim := Char($D9); // La
  TFarsi.SzLaStickWoosim := Char($D9); // La

  // TFarsi.ArrStruc[0]:= a;
  { Array }
  // TFarsi.ArrStruc:=
  // [
  SetLength(TFarsi.ArrStruc, 43);
  TFarsi.ArrStruc[0] := TStruc.Create(Char($630), Char($FEAC), Char($FEAB),
    Char($FEAC), Char($FEAB));
  TFarsi.ArrStruc[1] := TStruc.Create(Char($62F), Char($FEAA), Char($FEA9),
    Char($FEAA), Char($FEA9));
  TFarsi.ArrStruc[2] := TStruc.Create(Char($62C), Char($FE9E), Char($FE9F),
    Char($FEA0), Char($FE9D));
  TFarsi.ArrStruc[3] := TStruc.Create(Char($62D), Char($FEA2), Char($FEA3),
    Char($FEA4), Char($FEA1));
  TFarsi.ArrStruc[4] := TStruc.Create(Char($62E), Char($FEA6), Char($FEA7),
    Char($FEA8), Char($FEA5));
  TFarsi.ArrStruc[5] := TStruc.Create(Char($647), Char($FEEA), Char($FEEB),
    Char($FEEC), Char($FEE9));
  TFarsi.ArrStruc[6] := TStruc.Create(Char($639), Char($FECA), Char($FECB),
    Char($FECC), Char($FEC9));
  TFarsi.ArrStruc[7] := TStruc.Create(Char($63A), Char($FECE), Char($FECF),
    Char($FED0), Char($FECD));
  TFarsi.ArrStruc[8] := TStruc.Create(Char($641), Char($FED2), Char($FED3),
    Char($FED4), Char($FED1));
  TFarsi.ArrStruc[9] := TStruc.Create(Char($642), Char($FED6), Char($FED7),
    Char($FED8), Char($FED5));
  TFarsi.ArrStruc[10] := TStruc.Create(Char($62B), Char($FE9A), Char($FE9B),
    Char($FE9C), Char($FE99));
  TFarsi.ArrStruc[11] := TStruc.Create(Char($635), Char($FEBA), Char($FEBB),
    Char($FEBC), Char($FEB9));
  TFarsi.ArrStruc[12] := TStruc.Create(Char($636), Char($FEBE), Char($FEBF),
    Char($FEC0), Char($FEBD));
  TFarsi.ArrStruc[13] := TStruc.Create(Char($637), Char($FEC2), Char($FEC3),
    Char($FEC4), Char($FEC1));
  TFarsi.ArrStruc[14] := TStruc.Create(Char($643), Char($FEDA), Char($FEDB),
    Char($FEDC), Char($FED9));
  TFarsi.ArrStruc[15] := TStruc.Create(Char($645), Char($FEE2), Char($FEE3),
    Char($FEE4), Char($FEE1));
  TFarsi.ArrStruc[16] := TStruc.Create(Char($646), Char($FEE6), Char($FEE7),
    Char($FEE8), Char($FEE5));
  TFarsi.ArrStruc[17] := TStruc.Create(Char($62A), Char($FE96), Char($FE97),
    Char($FE98), Char($FE95));
  TFarsi.ArrStruc[18] := TStruc.Create(Char($627), Char($FE8E), Char($FE8D),
    Char($FE8E), Char($FE8D));
  TFarsi.ArrStruc[19] := TStruc.Create(Char($644), Char($FEDE), Char($FEDF),
    Char($FEE0), Char($FEDD));
  TFarsi.ArrStruc[20] := TStruc.Create(Char($628), Char($FE90), Char($FE91),
    Char($FE92), Char($FE8F));
  TFarsi.ArrStruc[21] := TStruc.Create(Char($64A), Char($FEF2), Char($FEF3),
    Char($FEF4), Char($FEF1));
  TFarsi.ArrStruc[22] := TStruc.Create(Char($633), Char($FEB2), Char($FEB3),
    Char($FEB4), Char($FEB1));
  TFarsi.ArrStruc[23] := TStruc.Create(Char($634), Char($FEB6), Char($FEB7),
    Char($FEB8), Char($FEB5));
  TFarsi.ArrStruc[24] := TStruc.Create(Char($638), Char($FEC6), Char($FEC7),
    Char($FEC8), Char($FEC5));
  TFarsi.ArrStruc[25] := TStruc.Create(Char($632), Char($FEB0), Char($FEAF),
    Char($FEB0), Char($FEAF));
  TFarsi.ArrStruc[26] := TStruc.Create(Char($648), Char($FEEE), Char($FEED),
    Char($FEEE), Char($FEED));
  TFarsi.ArrStruc[27] := TStruc.Create(Char($629), Char($FE94), Char($FE93),
    Char($FE93), Char($FE93));
  TFarsi.ArrStruc[28] := TStruc.Create(Char($649), Char($FEF0), Char($FEEF),
    Char($FEF0), Char($FEEF));
  TFarsi.ArrStruc[29] := TStruc.Create(Char($631), Char($FEAE), Char($FEAD),
    Char($FEAE), Char($FEAD));
  TFarsi.ArrStruc[30] := TStruc.Create(Char($624), Char($FE86), Char($FE85),
    Char($FE86), Char($FE85));
  TFarsi.ArrStruc[31] := TStruc.Create(Char($621), Char($FE80), Char($FE80),
    Char($FE80), Char($FE80));
  TFarsi.ArrStruc[32] := TStruc.Create(Char($626), Char($FE8A), Char($FE8B),
    Char($FE8C), Char($FE89));
  TFarsi.ArrStruc[33] := TStruc.Create(Char($623), Char($FE84), Char($FE83),
    Char($FE84), Char($FE83));
  TFarsi.ArrStruc[34] := TStruc.Create(Char($622), Char($FE82), Char($FE81),
    Char($FE82), Char($FE81));
  TFarsi.ArrStruc[35] := TStruc.Create(Char($625), Char($FE88), Char($FE87),
    Char($FE88), Char($FE87));
  TFarsi.ArrStruc[36] := TStruc.Create(Char($67E), Char($FB57), Char($FB58),
    Char($FB59), Char($FB56));
  TFarsi.ArrStruc[37] := TStruc.Create(Char($686), Char($FB7B), Char($FB7C),
    Char($FB7D), Char($FB7A));
  TFarsi.ArrStruc[38] := TStruc.Create(Char($698), Char($FB8B), Char($FB8A),
    Char($FB8B), Char($FB8A));
  TFarsi.ArrStruc[39] := TStruc.Create(Char($6A9), Char($FB8F), Char($FB90),
    Char($FB91), Char($FB8E));
  TFarsi.ArrStruc[40] := TStruc.Create(Char($6AF), Char($FB93), Char($FB94),
    Char($FB95), Char($FB92));
  TFarsi.ArrStruc[41] := TStruc.Create(Char($6CC), Char($FBFD), Char($FEF3),
    Char($FEF4), Char($FBFC));
  TFarsi.ArrStruc[42] := TStruc.Create(Char($6C0), Char($FBA5), Char($FBA4),
    Char($FBA5), Char($FBA4));
  // ];

  // TFarsi.ArrStrucWoosim:=
  // [
  SetLength(TFarsi.ArrStrucWoosim, 43);
  TFarsi.ArrStrucWoosim[0] := TStruc.Create(Char($630), Char($B5), Char($82),
    Char($B5), Char($82));
  TFarsi.ArrStrucWoosim[1] := TStruc.Create(Char($62F), Char($B4), Char($81),
    Char($B4), Char($81));
  TFarsi.ArrStrucWoosim[2] := TStruc.Create(Char($62C), Char($9B), Char($B1),
    Char($F9), Char($BF));
  TFarsi.ArrStrucWoosim[3] := TStruc.Create(Char($62D), Char($9C), Char($B2),
    Char($FA), Char($C0));
  TFarsi.ArrStrucWoosim[4] := TStruc.Create(Char($62E), Char($9D), Char($B3),
    Char($FE), Char($C1));
  TFarsi.ArrStrucWoosim[5] := TStruc.Create(Char($647), Char($AC), Char($E4),
    Char($93), Char($D5));
  TFarsi.ArrStrucWoosim[6] := TStruc.Create(Char($639), Char($C9), Char($D3),
    Char($8B), Char($A4));
  TFarsi.ArrStrucWoosim[7] := TStruc.Create(Char($63A), Char($CA), Char($DD),
    Char($8C), Char($A5));
  TFarsi.ArrStrucWoosim[8] := TStruc.Create(Char($641), Char($A6), Char($DE),
    Char($8D), Char($CC));
  TFarsi.ArrStrucWoosim[9] := TStruc.Create(Char($642), Char($A7), Char($DF),
    Char($8E), Char($CE));
  TFarsi.ArrStrucWoosim[10] := TStruc.Create(Char($62B), Char($BD), Char($AF),
    Char($EA), Char($99));
  TFarsi.ArrStrucWoosim[11] := TStruc.Create(Char($635), Char($C4), Char($C8),
    Char($87), Char($A0));
  TFarsi.ArrStrucWoosim[12] := TStruc.Create(Char($636), Char($C5), Char($CB),
    Char($88), Char($A1));
  TFarsi.ArrStrucWoosim[13] := TStruc.Create(Char($637), Char($C6), Char($CD),
    Char($CD), Char($A2));
  TFarsi.ArrStrucWoosim[14] := TStruc.Create(Char($643), Char($CF), Char($E0),
    Char($8F), Char($A8));
  TFarsi.ArrStrucWoosim[15] := TStruc.Create(Char($645), Char($D2), Char($E2),
    Char($91), Char($AA));
  TFarsi.ArrStrucWoosim[16] := TStruc.Create(Char($646), Char($D4), Char($E3),
    Char($92), Char($AB));
  TFarsi.ArrStrucWoosim[17] := TStruc.Create(Char($62A), Char($BD), Char($AF),
    Char($EA), Char($99));
  TFarsi.ArrStrucWoosim[18] := TStruc.Create(Char($627), Char($BB), Char($80),
    Char($BB), Char($80));
  TFarsi.ArrStrucWoosim[19] := TStruc.Create(Char($644), Char($D1), Char($E1),
    Char($90), Char($A9));
  TFarsi.ArrStrucWoosim[20] := TStruc.Create(Char($628), Char($BC), Char($AE),
    Char($E9), Char($98));
  TFarsi.ArrStrucWoosim[21] := TStruc.Create(Char($64A), Char($DC), Char($E6),
    Char($95), Char($DC));
  TFarsi.ArrStrucWoosim[22] := TStruc.Create(Char($633), Char($C2), Char($B8),
    Char($B8), Char($9E));
  TFarsi.ArrStrucWoosim[23] := TStruc.Create(Char($634), Char($C3), Char($B9),
    Char($B9), Char($9F));
  TFarsi.ArrStrucWoosim[24] := TStruc.Create(Char($638), Char($C7), Char($CD),
    Char($CD), Char($C7));
  TFarsi.ArrStrucWoosim[25] := TStruc.Create(Char($632), Char($B7), Char($B7),
    Char($B7), Char($B7));
  TFarsi.ArrStrucWoosim[26] := TStruc.Create(Char($648), Char($94), Char($94),
    Char($94), Char($94));
  TFarsi.ArrStrucWoosim[27] := TStruc.Create(Char($629), Char($DA), Char($DA),
    Char($DA), Char($DA));
  TFarsi.ArrStrucWoosim[28] := TStruc.Create(Char($649), Char($DC), Char($E6),
    Char($95), Char($DC));
  TFarsi.ArrStrucWoosim[29] := TStruc.Create(Char($631), Char($B6), Char($B6),
    Char($B6), Char($B6));
  TFarsi.ArrStrucWoosim[30] := TStruc.Create(Char($624), Char($E7), Char($E7),
    Char($E7), Char($E7));
  TFarsi.ArrStrucWoosim[31] := TStruc.Create(Char($621), Char($BA), Char($BA),
    Char($BA), Char($BA));
  TFarsi.ArrStrucWoosim[32] := TStruc.Create(Char($626), Char($D7), Char($E8),
    Char($97), Char($D7));
  TFarsi.ArrStrucWoosim[33] := TStruc.Create(Char($623), Char($80), Char($80),
    Char($80), Char($80));
  TFarsi.ArrStrucWoosim[34] := TStruc.Create(Char($622), Char($80), Char($80),
    Char($80), Char($80));
  TFarsi.ArrStrucWoosim[35] := TStruc.Create(Char($625), Char($80), Char($80),
    Char($80), Char($80));
  TFarsi.ArrStrucWoosim[36] := TStruc.Create(Char($67E), Char($BC), Char($AE),
    Char($E9), Char($98));
  TFarsi.ArrStrucWoosim[37] := TStruc.Create(Char($686), Char($9B), Char($B1),
    Char($F9), Char($BF));
  TFarsi.ArrStrucWoosim[38] := TStruc.Create(Char($698), Char($B7), Char($B7),
    Char($B7), Char($B7));
  TFarsi.ArrStrucWoosim[39] := TStruc.Create(Char($6A9), Char($CF), Char($E0),
    Char($8F), Char($A8));
  TFarsi.ArrStrucWoosim[40] := TStruc.Create(Char($6AF), Char($CF), Char($E0),
    Char($8F), Char($A8));
  TFarsi.ArrStrucWoosim[41] := TStruc.Create(Char($6CC), Char($DC), Char($E6),
    Char($95), Char($DC));
  TFarsi.ArrStrucWoosim[42] := TStruc.Create(Char($6C0), Char($AC), Char($E4),
    Char($93), Char($D5));
  // ];
end;

class function TFarsi.IsFarsiChar(Ch: Char): Boolean;
begin
  Result := ((Ch >= Char($0621)) and (Ch <= Char($064A))) or (Ch = Char($067E))
    or (Ch = Char($0686)) or (Ch = Char($0698)) or (Ch = Char($06A9)) or
    (Ch = Char($06AF)) or (Ch = Char($06CC)) or (Ch = Char($06C0)) or
    ((Ch >= Char($FB50)) and (Ch <= Char($FEFC)));
end;

class function TFarsi.IsFromTheSet1(Ch: Char): Boolean;
var
  LTheSet1: array of Char;
  I: Integer;
begin
  Result := False;
  I := 0;
  // LTheSet1:= [
  SetLength(LTheSet1, 28);
  LTheSet1[0] := Char($62C);
  LTheSet1[1] := Char($62D);
  LTheSet1[2] := Char($62E);
  LTheSet1[3] := Char($647);
  LTheSet1[4] := Char($639);
  LTheSet1[5] := Char($63A);
  LTheSet1[6] := Char($641);
  LTheSet1[7] := Char($642);
  LTheSet1[8] := Char($62B);
  LTheSet1[9] := Char($635);
  LTheSet1[10] := Char($636);
  LTheSet1[11] := Char($637);
  LTheSet1[12] := Char($643);
  LTheSet1[13] := Char($645);
  LTheSet1[14] := Char($646);
  LTheSet1[15] := Char($62A);
  LTheSet1[16] := Char($644);
  LTheSet1[17] := Char($628);
  LTheSet1[18] := Char($64A);
  LTheSet1[19] := Char($633);
  LTheSet1[20] := Char($634);
  LTheSet1[21] := Char($638);
  LTheSet1[22] := Char($67E);
  LTheSet1[23] := Char($686);
  LTheSet1[24] := Char($6A9);
  LTheSet1[25] := Char($6AF);
  LTheSet1[26] := Char($6CC);
  LTheSet1[27] := Char($626);
  // ];

  while (I < 28) do
  begin
    if Ch = LTheSet1[I] then
      Exit(True);

    Inc(I);
  end;
end;

class function TFarsi.IsFromTheSet2(Ch: Char): Boolean;
var
  LTheSet2: array of Char;
  I: Integer;
begin
  Result := False;
  I := 0;
  // LTheSet2:= [
  SetLength(LTheSet2, 14);
  LTheSet2[0] := Char($627);
  LTheSet2[1] := Char($623);
  LTheSet2[2] := Char($625);
  LTheSet2[3] := Char($622);
  LTheSet2[4] := Char($62F);
  LTheSet2[5] := Char($630);

  LTheSet2[6] := Char($631);
  LTheSet2[7] := Char($632);
  LTheSet2[8] := Char($648);
  LTheSet2[9] := Char($624);
  LTheSet2[10] := Char($629);
  LTheSet2[11] := Char($649);

  LTheSet2[12] := Char($698);
  LTheSet2[13] := Char($6C0);
  // ];

  while (I < 14) do
  begin
    if Ch = LTheSet2[I] then
      Exit(True);

    Inc(I);
  end;
end;

class function TFarsi.IsSpecialChar(Ch: Char): Boolean;
begin
  Result := ((Ch >= Char($00)) and (Ch <= Char($20))) or
    ((Ch >= Char($7F)) and (Ch <= Char($9F)));
end;

end.
