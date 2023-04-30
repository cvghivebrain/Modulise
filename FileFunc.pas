unit FileFunc;

interface
uses Windows, SysUtils;

procedure LoadFile(openthis: string);
procedure SaveFile(savethis: string);
procedure ClipFile(a, len: integer; clipthisfile: string);
procedure NewFile(filelen: integer);
procedure AddFile(a: integer; addthisfile: string);
procedure EvenFile;
function GetByte(a: integer): byte;
function GetBit(a, b: integer): byte;
function Bit(i, b: integer): byte;
function GetWord(a: integer): word;
function GetDword(a: integer): longword;
function GetWordRev(a: integer): word;
function GetDwordRev(a: integer): longword;
function GetString(a, maxlength: integer): string;
procedure WriteByte(a: integer; b: byte);
procedure WriteWord(a: integer; w: word);
procedure WriteWordRev(a: integer; w: word);
procedure WriteDword(a: integer; d: longword);
procedure WriteDwordRev(a: integer; d: longword);
procedure RunCommand(command: string);

var
  myfile: file;
  filearray: array of byte;
  fs: integer;

implementation

{ Copy file to memory. }

procedure LoadFile(openthis: string);
begin
  if FileExists(openthis) then
    begin
    AssignFile(myfile,openthis); // Get file.
    FileMode := fmOpenRead; // Read only.
    Reset(myfile,1);
    SetLength(filearray,FileSize(myfile)); // Match array size to file size.
    BlockRead(myfile,filearray[0],FileSize(myfile)); // Copy file to memory.
    CloseFile(myfile); // Close file.
    fs := Length(filearray);
    end;
end;

{ Save file from memory to file. }

procedure SaveFile(savethis: string);
begin
  AssignFile(myfile,savethis); // Open file.
  FileMode := fmOpenReadWrite;
  ReWrite(myfile,1);
  BlockWrite(myfile,filearray[0],Length(filearray)); // Copy contents of array to file.
  CloseFile(myfile); // Close file.
end;

{ Save section of file to another file. }

procedure ClipFile(a, len: integer; clipthisfile: string);
var myclipfile: file;
  clipfilearray: array of byte;
begin
  if a+len > fs then len := fs-a; // Don't allow clip to extend outside file.
  if a > fs then len := 0;
  AssignFile(myclipfile,clipthisfile); // Open file.
  FileMode := fmOpenReadWrite;
  ReWrite(myclipfile,1);
  SetLength(clipfilearray,len);
  Move(filearray[a],clipfilearray[0],len); // Copy specified section.
  BlockWrite(myclipfile,clipfilearray[0],len); // Copy contents of array to file.
  CloseFile(myclipfile); // Close file.
end;

{ Create new blank file. }

procedure NewFile(filelen: integer);
begin
  FillChar(filearray[0],fs,0); // Fill existing file with 0.
  SetLength(filearray,filelen);
  fs := filelen;
end;

{ Add file to existing file array. }

procedure AddFile(a: integer; addthisfile: string);
var myaddfile: file;
begin
  AssignFile(myaddfile,addthisfile); // Get file.
  FileMode := fmOpenRead; // Read only.
  Reset(myaddfile,1);
  if fs < a+FileSize(myaddfile) then SetLength(filearray,a+FileSize(myaddfile)); // Enlarge file if needed.
  BlockRead(myaddfile,filearray[a],FileSize(myaddfile)); // Copy file to array.
  CloseFile(myaddfile); // Close file.
  fs := Length(filearray);
end;

{ Make filesize even. }

procedure EvenFile;
begin
  if Odd(fs) then SetLength(filearray,fs+1); // Add 1 byte to end if odd.
  fs := Length(filearray);
end;

{ Get byte from file array. }

function GetByte(a: integer): byte;
begin
  result := filearray[a];
end;

{ Get bit from file array. }

function GetBit(a, b: integer): byte;
begin
  result := (filearray[a] and (1 shl b)) shr b;;
end;

{ Get bit from integer. }

function Bit(i, b: integer): byte;
begin
  result := (i and (1 shl b)) shr b;;
end;

{ Get word from file array. }

function GetWord(a: integer): word;
begin
  result := (filearray[a]*$100)+filearray[a+1];
end;

{ Get longword from file array. }

function GetDword(a: integer): longword;
begin
  result := (GetWord(a)*$10000)+GetWord(a+2);
end;

{ Get word (little endian) from file array. }

function GetWordRev(a: integer): word;
begin
  result := (filearray[a+1]*$100)+filearray[a];
end;

{ Get longword (little endian) from file array. }

function GetDwordRev(a: integer): longword;
begin
  result := (GetWordRev(a+2)*$10000)+GetWordRev(a);
end;

{ Get string from file array. }

function GetString(a, maxlength: integer): string;
begin
  result := '';
  while maxlength > 0 do
    begin
    Dec(maxlength);
    if filearray[a] in [32..126] then result := result+Chr(filearray[a]) // Add character to string if valid.
    else maxlength := 0; // Otherwise end the string.
    Inc(a); // Next character.
    end;
end;

{ Write single byte to file array. }

procedure WriteByte(a: integer; b: byte);
begin
  if fs < a+1 then SetLength(filearray,a+1); // Enlarge file if needed.
  filearray[a] := b;
  fs := Length(filearray);
end;

{ Write word to file array. }

procedure WriteWord(a: integer; w: word);
begin
  if fs < a+2 then SetLength(filearray,a+2); // Enlarge file if needed.
  filearray[a] := w shr 8;
  filearray[a+1] := w and $FF;
  fs := Length(filearray);
end;

{ Write word (little endian) to file array. }

procedure WriteWordRev(a: integer; w: word);
begin
  if fs < a+2 then SetLength(filearray,a+2); // Enlarge file if needed.
  filearray[a+1] := w shr 8;
  filearray[a] := w and $FF;
  fs := Length(filearray);
end;

{ Write longword to file array. }

procedure WriteDword(a: integer; d: longword);
begin
  if fs < a+4 then SetLength(filearray,a+4); // Enlarge file if needed.
  WriteWord(a,d shr 16);
  WriteWord(a+2,d and $FFFF);
  fs := Length(filearray);
end;

{ Write longword (little endian) to file array. }

procedure WriteDwordRev(a: integer; d: longword);
begin
  if fs < a+4 then SetLength(filearray,a+4); // Enlarge file if needed.
  WriteWordRev(a+2,d shr 16);
  WriteWordRev(a,d and $FFFF);
  fs := Length(filearray);
end;

{ Run an external program. }

procedure RunCommand(command: string);
var StartInfo: TStartupInfo;
  ProcInfo: TProcessInformation;
begin
  FillChar(StartInfo,SizeOf(TStartupInfo),#0);
  FillChar(ProcInfo,SizeOf(TProcessInformation),#0);
  StartInfo.cb := SizeOf(TStartupInfo);
  if CreateProcess(nil,PChar(command),nil,nil,false,CREATE_NEW_PROCESS_GROUP+NORMAL_PRIORITY_CLASS+CREATE_NO_WINDOW,nil,nil,StartInfo,ProcInfo) then
    begin
    CloseHandle(ProcInfo.hProcess);
    CloseHandle(ProcInfo.hThread);
    end;
end;

end.
