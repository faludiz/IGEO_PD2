unit mdtablegenerator;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Grids;

{
align:
h - hidden
l - left
c - center
r - right
}

function SGToMD(SG: TStringGrid; const align: array of char; const skiprowifcolvalueis0:integer=-1): TStringList;

implementation

uses
  lazutf8;

type
  TIntegerArray = array of integer;

function GetSGColWitdths(SG: TStringGrid): TIntegerArray;
var
  c, r, w: longint;
begin
  Result:=default(TIntegerArray);
  setlength(Result, SG.ColCount);

  if sg.Columns.Count > 0 then for c := 0 to sg.Columns.Count - 1 do sg.Cells[c, 0] := sg.Columns[c].Title.Caption;

  for c := 0 to SG.ColCount - 1 do begin
    w := 0;
    for r := 0 to SG.RowCount - 1 do begin
      if utf8length(SG.Cells[c, r]) > w then w := utf8length(SG.Cells[c, r]);
    end;
    if w < 3 then w := 3;
    Result[c] := w;
  end;
end;

function ParseSG(SG: TStringGrid; const align: array of char; const skiprowifcolvalueis0:integer=-1): TStringList;
var
  cw: TIntegerArray;
  i, j, r: integer;
  tmp, s: string;
begin
  Result := TStringList.Create;
  cw := GetSGColWitdths(SG);

  //táblázat sorai
  for r := 0 to sg.RowCount - 1 do begin

    if (skiprowifcolvalueis0>=0) and (SG.Cells[skiprowifcolvalueis0, r]='0') then continue;

    tmp := '|';
    for i := 0 to sg.ColCount - 1 do begin
      if align[i] = 'h' then continue;
      s := sg.Cells[i, r];

      if align[i] = 'l' then while utf8length(s) < cw[i] do s := s + ' ';
      if align[i] = 'r' then while utf8length(s) < cw[i] do s := ' ' + s;
      if align[i] = 'c' then begin
        j := 0;
        while utf8length(s) < cw[i] do begin
          if (j mod 2) = 0 then s := s + ' ' else s := ' ' + s;
          Inc(j);
        end;
      end;

      tmp := tmp + ' ' + s + ' |';
    end;

    Result.Add(tmp);

  end;

  //formátum léc
  tmp := '|';
  for i := 0 to sg.ColCount - 1 do begin
    if align[i] = 'h' then continue;
    s := '';
    while utf8length(s) < cw[i] do s := s + '-';

    if align[i] = 'l' then s[1] := ':';
    if align[i] = 'r' then s[utf8length(s)] := ':';
    if align[i] = 'c' then begin
      s[1] := ':';
      s[utf8length(s)] := ':';
    end;

    tmp := tmp + ' ' + s + ' |';
  end;
  if Result.Count>1 then Result.Insert(1, tmp);

end;

function SGToMD(SG: TStringGrid; const align: array of char; const skiprowifcolvalueis0:integer=-1): TStringList;
begin
  Result := TStringList.Create;
  Result.AddStrings(ParseSG(SG, align, skiprowifcolvalueis0));
end;

end.
