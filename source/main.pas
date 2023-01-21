unit main;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, SQLite3Conn, SQLDB, DB, Forms, Controls, Graphics, Dialogs,
  StdCtrls, Grids, ComCtrls, ExtCtrls, mdtablegenerator, inifiles, MarkdownUtils, MarkdownProcessor;

type

  { TfrmMain }

  TfrmMain = class(TForm)
    cbSaveHTML: TCheckBox;
    cbSaveKML: TCheckBox;
    edtCSS: TEdit;
    Label8: TLabel;
    Label9: TLabel;
    stnSave: TButton;
    cbRenumber: TCheckBox;
    cmbSeparator: TComboBox;
    Connection: TSQLite3Connection;
    edtIncrement: TEdit;
    edtStart: TEdit;
    edtLic: TEdit;
    edtUser: TEdit;
    edtTransf: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label5: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    memFbk: TMemo;
    memPts: TMemo;
    pcMain: TPageControl;
    Panel1: TPanel;
    Panel2: TPanel;
    Query: TSQLQuery;
    SB: TStatusBar;
    tsPts: TTabSheet;
    tsFbk: TTabSheet;
    tsOpt: TTabSheet;
    Transaction: TSQLTransaction;
    procedure FormActivate(Sender: TObject);
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure pcMainChange(Sender: TObject);
    procedure stnSaveClick(Sender: TObject);
  private
    fndb:string;
    fnoptions:string;
    procedure setconnection(const fn:string);
    function getversion:tstringlist;
    function getantenna:tstringlist;
    function getbasedata(const gpsid:string):tstringlist;
    function getpointdata(const gpsid:string):tstringlist;
    function getstakedata(const gpsid:string):tstringlist;
    procedure SaveOptions;
    procedure LoadOptions;
    function GetDelimiter:char;
  public

  end;

var
  frmMain: TfrmMain;

const
  defaultCSS = '<style type="text/css">body { font-family: sans-serif; } table { width: 100%; border-collapse: collapse; } table, th, td { padding: 2px; border: 1px solid black; }</style>';

implementation

{$R *.lfm}

{ TfrmMain }

function sr(const s:string; const roundto:byte):string;
var
  d:double;
  fmt:string;
begin
  d:=0;
  trystrtofloat(s,d);
  fmt:='%0.'+inttostr(roundto)+'f';
  result:=format(fmt,[d]);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  lst:tstringlist;
  pt,fbk,pts,dat,baselist:tstringlist;
  gpsid:string;
  base:string;
  sg:tstringgrid;
  row:integer;
  i,j:integer;
  pnum:integer;
  pinc:integer;
  md: TMarkdownProcessor;
  body, html: TStringList;
  kml: TStringList;
begin
  memFbk.Clear;
  memPts.Clear;

  DefaultFormatSettings.DecimalSeparator:='.';

  fnoptions:=GetAppConfigFile(False);
  LoadOptions;

  tsFbk.TabVisible:=false;
  tsPts.TabVisible:=false;
  pcMain.ActivePage:=tsOpt;

  if paramcount = 0 then exit;

  if fileexists(paramstr(1)) then setconnection(paramstr(1));

  if not Connection.Connected then exit;

  sb.SimpleText:=expandfilename(fndb);

  tsFbk.TabVisible:=true;
  tsPts.TabVisible:=True;

  fbk:=tstringlist.Create;
  pts:=tstringlist.Create;
  pt:=tstringlist.Create;
  dat:=tstringlist.Create;
  baselist:=tstringlist.Create;

  sg:=tstringgrid.Create(self);
  sg.RowCount:=1;
  sg.ColCount:=5;
  sg.Cells[0,0]:='Pont';
  sg.Cells[1,0]:='WGS84';
  sg.Cells[2,0]:='EOV';
  sg.Cells[3,0]:='Hiba';
  sg.Cells[4,0]:='Megoldás';

  fbk.Add('# Mérési jegyzőkönyv');
  fbk.Add('');
  fbk.Add('## Projekt');
  fbk.Add('');
  fbk.Add('- Név:           '#9'%s',[ extractfilename(paramstr(1))]);
  fbk.Add('- Transzformáció:'#9+edtTransf.Text);
  fbk.Add('- Licenc:        '#9+edtLic.Text);
  fbk.Add('- Felmérő neve:  '#9+edtUser.Text);
  fbk.Add('');
  fbk.Add('## Szoftver');
  fbk.Add('');
  fbk.Add('- Név:   '#9'SurPad / SurvX');
  fbk.Add('- Verzió:'#9'%s', [ getversion[0]] );
  fbk.Add('');
  fbk.Add('## Antenna');
  lst:=getantenna;
  fbk.Add('');
  fbk.Add('- ID: '#9'%s', [ lst[0] ] );
  fbk.Add('- H:  '#9'%s', [ lst[2] ] );
  fbk.Add('- R:  '#9'%s', [ lst[3] ] );
  fbk.Add('- HL1:'#9'%s', [ lst[4] ] );
  fbk.Add('- HL2:'#9'%s', [ lst[5] ] );

  Query.Active:=false;
  Query.SQL.Text:='select * from point where (deletesign=0 and GPSID<>"")';

  Query.ExecSQL;

  Query.Active:=true;

  Query.First;

  base:='';

  pnum:=strtoint(edtStart.Text);
  pinc:=strtoint(edtIncrement.Text);

  while not Query.EOF do begin

    gpsid:=Query.FieldValues['gpsid'];

    pt.Clear;
    if cbRenumber.Checked then begin
      pt.Add(inttostr(pnum));
      pnum:=pnum+pinc;
    end else begin
      pt.Add(Query.FieldValues['name']);           //0
    end;
    pt.Add(Query.FieldValues['code']);             //1
    pt.Add(sr(Query.FieldValues['latitude'],9));   //2
    pt.Add(sr(Query.FieldValues['longitude'],9));  //3
    pt.Add(sr(Query.FieldValues['altitude'],3));   //4
    pt.Add(sr(Query.FieldValues['east'],3));       //5
    pt.Add(sr(Query.FieldValues['north'],3));      //6
    pt.Add(sr(Query.FieldValues['height'],3));     //7

    lst:=getpointdata(gpsid);

    pt.AddStrings(lst); //8:locked, 9:tracked, 10:hrms, 11:vrms, 12:pdop, 13:state, 14:date, 15:time, 16:anth

    lst:=getbasedata(gpsid);
    pt.AddStrings(lst); //17:baseid, 18:blat, 19:blon, 20:balt, 21:bsn

    lst:=getstakedata(gpsid);
    if lst.Count>0 then pt.AddStrings(lst); //22:target, 23:dx, 24:dy, 25:dh

    pts.Add(pt.CommaText);

    Query.Next;

  end;

  //bázis lista
  baselist.Clear;

  for i:=0 to pts.Count-1 do begin
    pt.CommaText:=pts[i];
    base:=format('%s,%s,%s,%s,%s',[
      pt[17],
      pt[18],
      pt[19],
      pt[20],
      pt[21]
    ]);
    if baselist.IndexOf(base)<0 then baselist.Add(base);
  end;

  //mérési jegyzőkönyv

  for i:=0 to baselist.count-1 do begin

    dat.CommaText:=baselist[i];

    fbk.Add('');
    fbk.Add('## Bázis');
    fbk.Add('');
    fbk.Add('- ID :'#9'%s',[ dat[0] ]);
    fbk.Add('- Lat:'#9'%s',[ dat[1] ]);
    fbk.Add('- Lon:'#9'%s',[ dat[2] ]);
    fbk.Add('- Alt:'#9'%s',[ dat[3] ]);
    fbk.Add('- Sn: '#9'%s',[ dat[4] ]);
    fbk.Add('');
    fbk.Add('### Mért pontok');
    fbk.Add('');

    sg.RowCount:=1;

    for j:=0 to pts.Count-1 do begin
      pt.CommaText:=pts[j];
      base:=format('%s,%s,%s,%s,%s',[
        pt[17],
        pt[18],
        pt[19],
        pt[20],
        pt[21]
      ]);
      if base=baselist[i] then begin
        dat.CommaText:=pts[j];

        sg.RowCount:=sg.RowCount+3;
        row:=sg.RowCount-3;

        sg.Cells[0, row+0]:= dat[0];         //psz
        sg.Cells[0, row+1]:= dat[1];         //kód
        sg.Cells[0, row+2]:= 'Jm='+dat[16];  //jm

        sg.Cells[1, row+0]:= dat[2];         //lat
        sg.Cells[1, row+1]:= dat[3];         //lon
        sg.Cells[1, row+2]:= dat[4];         //alt

        sg.Cells[2, row+0]:= dat[5];         //y
        sg.Cells[2, row+1]:= dat[6];         //x
        sg.Cells[2, row+2]:= dat[7];         //z

        sg.Cells[3, row+0]:= 'hrms='+dat[10]; //hrms
        sg.Cells[3, row+1]:= 'vrms='+dat[11]; //vrms
        sg.Cells[3, row+2]:= 'pdop='+dat[12]; //pdop

        sg.Cells[4, row+0]:= dat[8] + '/' + dat[9] + ' ' + dat[13];  // locked/tracked state
        sg.Cells[4, row+1]:= dat[14];         //dátum
        sg.Cells[4, row+2]:= dat[15];         //idő

        //kitűzés? //22:target, 23:dx, 24:dy, 25:dh
        if dat.Count>23 then begin
          sg.RowCount:=sg.RowCount+1;
          sg.Cells[0, row+3]:='Kitűzés';
          sg.Cells[1, row+3]:='dy='+dat[23];
          sg.Cells[2, row+3]:='dx='+dat[24];
          sg.Cells[3, row+3]:='dh='+dat[25];
          sg.Cells[4, row+3]:=dat[22];
        end;

        sg.RowCount:=sg.RowCount+1;          //üres sor

      end;
    end;

    sg.RowCount:=sg.RowCount-1;

    fbk.AddStrings( sgtomd(sg, 'lrrrl') );

  end;

  fbk.Add('');
  fbk.Add('> Létrehozva az [IGEO.PD2](https://github.com/faludiz/IGEO_PD2) v22.12.03 alkalmazással');

  memFbk.Lines.AddStrings(fbk);

  //md -> html
  md   := TMarkdownProcessor.createDialect(mdCommonMark);
  md.UnSafe := True;
  body := TStringList.Create;
  body.Text := md.process(memFbk.Text);
  html := TStringList.Create;
  html.Add('<!DOCTYPE html>');
  html.Add('<html lang="hu">');
  html.Add('<head>');
  html.Add('<meta charset="utf-8">');
  html.Add('<meta name="generator" content="igeo.pd2" >');
  html.Add('<title>Mérési Jegyzőkönyv | '+extractfilename(paramstr(1))+'</title>');
  html.Add(edtCSS.Text);
  html.Add('</head>');
  html.Add('<body>');
  html.AddStrings(body);
  html.Add('</body>');
  html.Add('</html>');
  md.free;


  //koordináta jegyzék
  dat.Delimiter:=GetDelimiter;
  kml:=tstringlist.Create;

  //  kml fejléc
  kml.Add('<?xml version="1.0" encoding="UTF-8"?>');
  kml.Add('<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">');
  kml.Add('<Document>');
  kml.Add(format('  <name>%s</name>', [extractfilename(paramstr(1))]));
  kml.Add('  <Folder>');
  kml.Add('    <name>Pontok</name>');
  kml.Add('    <open>1</open>');

  for i:=0 to pts.Count-1 do begin
    pt.commatext:=pts[i];
    dat.Clear;
    dat.Add(pt[0]); //psz
    dat.Add(pt[5]); //y
    dat.Add(pt[6]); //x
    dat.Add(pt[7]); //z
    dat.Add(pt[1]); //kód
    dat.Add(pt[13]); //státusz
    dat.Add(pt[10]); //hrms
    dat.Add(pt[11]); //vrms
    dat.Add(pt[12]); //pdop
    memPts.lines.Add(dat.DelimitedText);

    //kml
    kml.Add('  <Placemark>');
    kml.Add(format('    <name>%s</name>',[  pt[0]  ] ));
    kml.Add(format('    <description>%s</description>', [ pt[1] ]));
    kml.Add(format('    <Point><coordinates>%s,%s,%s</coordinates></Point>', [ pt[3], pt[2], pt[4]   ]));
    kml.Add('  </Placemark>');

  end;

  //  kml láb
  kml.Add('  </Folder>');
  kml.Add('</Document>');
  kml.Add('</kml>');

  memFbk.Lines.SaveToFile( changefileext(fndb,'.fbk.md') );
  memPts.Lines.SaveToFile( changefileext(fndb,'.pts.txt') );
  if cbSaveHtml.Checked then html.SaveToFile(changefileext(fndb,'.fbk.html'));
  if cbSaveKml.Checked then kml.SaveToFile(changefileext(fndb,'.pts.kml'));

  Connection.Close();

end;

procedure TfrmMain.pcMainChange(Sender: TObject);
begin
  // lap váltáskor az editor legyen aktív
  if pcMain.ActivePage=tsPts then memPts.SetFocus;
  if pcMain.ActivePage=tsFbk then memFbk.SetFocus;
end;

procedure TfrmMain.stnSaveClick(Sender: TObject);
begin
  SaveOptions;
end;

procedure TfrmMain.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  if Connection.Connected then Connection.Close();
  SaveOptions;
end;

procedure TfrmMain.FormActivate(Sender: TObject);
begin
  pcMain.ActivePage:=tsFbk;
  pcMainChange(Sender);
end;

procedure TfrmMain.setconnection(const fn: string);
begin
  Connection.DatabaseName:=fn;
  Connection.Connected:=true;
  fndb:=fn;
end;

function TfrmMain.getversion: tstringlist;
var
  q:TSQLQuery;
begin
  result:=tstringlist.Create;
  q:=TSQLQuery.Create(nil);
  q.DataBase:=Connection;
  q.SQL.Text:='select * from version';
  q.ExecSQL;
  q.Active:=true;
  q.First;
  if q.RecordCount>0 then begin
    result.Add( q.FieldValues['soft_ver'] );
  end else begin
    result.Add('?');
  end;
  q.Free;
end;

function TfrmMain.getantenna: tstringlist;
var
  q:TSQLQuery;
begin
  result:=tstringlist.Create;
  q:=TSQLQuery.Create(nil);
  q.DataBase:=Connection;
  q.SQL.Text:='select * from antenna';
  q.ExecSQL;
  q.Active:=true;
  q.First;
  result.Add( q.FieldValues['id'] );         //0
  result.Add( q.FieldValues['type'] );       //1
  result.Add( sr(q.FieldValues['h'],4) );    //2
  result.Add( sr(q.FieldValues['r'],4) );    //3
  result.Add( sr(q.FieldValues['hl1'],4) );  //4
  result.Add( sr(q.FieldValues['hl2'],4) );  //5
  q.Free;
end;

function TfrmMain.getbasedata(const gpsid: string): tstringlist;
var
  q:TSQLQuery;
begin
  result:=tstringlist.Create;
  q:=TSQLQuery.Create(nil);
  q.DataBase:=Connection;
  q.SQL.Text:=format('select * from GPSCoordinate where id="%s"', [gpsid] );
  q.ExecSQL;
  q.Active:=true;
  q.First;
  result.Add( q.FieldValues['base_id'] );              //0
  result.Add( sr(q.FieldValues['base_latitude'],9) );  //1
  result.Add( sr(q.FieldValues['base_longitude'],9) ); //2
  result.Add( sr(q.FieldValues['base_altitude'],3) );  //3
  result.Add( q.FieldValues['base_sn'] );              //4
  q.Free;
end;

function TfrmMain.getpointdata(const gpsid: string): tstringlist;
var
  q:TSQLQuery;
  i:integer;
begin
  result:=tstringlist.Create;
  q:=TSQLQuery.Create(nil);
  q.DataBase:=Connection;
  q.SQL.Text:=format('select * from GPSCoordinate where id="%s"', [gpsid] );
  q.ExecSQL;
  q.Active:=true;
  q.First;
  if q.RecordCount>0 then begin;
    result.Add( q.FieldValues['satellite_locked'] );             //0
    result.Add( q.FieldValues['satellite_tracked'] );            //1
    result.Add( sr(q.FieldValues['hrms'],3) );                   //2
    result.Add( sr(q.FieldValues['vrms'],3) );                   //3
    result.Add( sr(q.FieldValues['pdop'],3) );                   //4
    result.Add( q.FieldValues['pos_state'] );                    //5
    result.Add( q.FieldValues['localdate'] );                    //6
    result.Add( q.FieldValues['localtime'] );                    //7
    result.Add( sr(q.FieldValues['antenna_measureheight'],3) );  //8
  end else begin
    for i:=0 to 8 do result.Add('0');
  end;
  q.Free;
end;

function TfrmMain.getstakedata(const gpsid: string): tstringlist;
var
  q:TSQLQuery;
begin
  result:=tstringlist.Create;
  q:=TSQLQuery.Create(nil);
  q.DataBase:=Connection;
  q.SQL.Text:=format('select * from stakeout where (gpsid="%s" and target<>"")', [gpsid] );
  q.ExecSQL;
  q.Active:=true;
  q.First;
  if q.RecordCount>0 then begin;
    result.Add( ansistring(q.FieldValues['target']) ); //0 - cél
    result.Add( sr(q.FieldValues['dx'],3) );
    result.Add( sr(q.FieldValues['dy'],3) );
    result.Add( sr(q.FieldValues['dh'],3) );
  end;
  q.Free;
end;

procedure TfrmMain.SaveOptions;
var
  ini:tinifile;
begin
  ini:=tinifile.Create(fnoptions);
  ini.WriteString(application.Title, 'user',edtUser.Text);
  ini.WriteString(application.Title, 'transf', edtTransf.Text);
  ini.WriteString(application.Title, 'lic', edtLic.Text);
  ini.WriteInteger(application.Title, 'separator', cmbSeparator.ItemIndex);
  ini.WriteBool(application.Title, 'renumber', cbRenumber.Checked);
  ini.WriteString(application.Title, 'start', edtStart.Text);
  ini.WriteString(application.Title, 'increment', edtIncrement.Text);
  ini.WriteString(application.Title, 'css', edtCSS.Text);
  ini.WriteInteger(application.Title, 'left', self.Left);
  ini.WriteInteger(application.Title, 'top', self.Top);
  ini.WriteInteger(application.Title, 'width', self.Width);
  ini.WriteInteger(application.Title, 'height', self.Height);
  ini.WriteBool(application.Title,'savehtml',cbSaveHtml.Checked);
  ini.WriteBool(application.Title, 'savekml', cbSaveKml.Checked);
  ini.Free;
end;

procedure TfrmMain.LoadOptions;
var
  ini:tinifile;
begin
  ini:=tinifile.Create(fnoptions);
  edtUser.Text:=ini.ReadString(application.Title, 'user', 'Gém Géza');
  edtTransf.Text:=ini.ReadString(application.Title, 'transf', 'VITEL 2014');
  edtLic.Text:=ini.ReadString(application.Title, 'lic', '');
  cmbSeparator.ItemIndex:=ini.ReadInteger(application.Title, 'separator', 0);
  cbRenumber.Checked:=ini.ReadBool(application.Title, 'renumber', false);
  edtStart.Text:=ini.ReadString(application.Title, 'start', '2001');
  edtIncrement.Text:=ini.ReadString(application.Title, 'increment', '1');
  edtCSS.Text:=ini.ReadString(application.Title,'css', defaultCSS);
  self.Left:=ini.ReadInteger(application.Title, 'left', 100);
  self.top:=ini.ReadInteger(application.Title, 'top', 100);
  self.Width:=ini.ReadInteger(application.Title, 'width', 800);
  self.Height:=ini.ReadInteger(application.Title, 'height', 600);
  cbSaveHtml.Checked:=ini.ReadBool(application.Title, 'savehtml', false);
  cbSaveKml.Checked:=ini.ReadBool(application.Title, 'savekml', false);
end;

function TfrmMain.GetDelimiter: char;
begin
  {
  0 vessző
  1 pontosvessző
  2 szóköz
  3 tabulátor
  }
  case cmbSeparator.ItemIndex of
    0: result:=',';
    1: result:=';';
    2: result:=' ';
    3: result:=#9;
  end;
end;

end.

