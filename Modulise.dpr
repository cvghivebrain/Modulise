program PModulise;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  FileFunc in 'FileFunc.pas';

var
  i, modsize, modcount, lastmodsize: integer;

label endnow;

begin
  { Program start }

  if ParamCount < 4 then goto endnow; // End program if run without parameters.
  if FileExists(ParamStr(1)) = false then goto endnow; // End if compressor doesn't exist.
  if TryStrToInt(ParamStr(2),modsize) = false then goto endnow; // End if module size is invalid.
  if FileExists(ParamStr(3)) = false then goto endnow; // End if file doesn't exist.

  modsize := StrToInt(ParamStr(2)); // Set size of modules.
  LoadFile(ParamStr(3));
  lastmodsize := fs mod modsize;
  modcount := fs div modsize;
  if lastmodsize > 0 then Inc(modcount);
  for i := 0 to modcount-1 do
    begin
    ClipFile(i*modsize,modsize,IntToStr(i)+'.tmp'); // Split module from main file.
    RunCommand(ParamStr(1)+' '+IntToStr(i)+'.tmp'+' '+IntToStr(i)+'.tmp.cmp'); // Compress.
    DeleteFile(IntToStr(i)+'.tmp'); // Delete uncompressed module.
    end;
  NewFile(2); // Start a new file.
  if ParamStr(5) = '-s' then WriteWord(0,((modcount-1) shl 12)+lastmodsize) // Use short header.
  else
    begin
    WriteWord(0,modcount-1);
    WriteWord(((modcount-1)*2)+4,lastmodsize); // Create blank index.
    end;
  for i := 0 to modcount-1 do
    begin
    if ParamStr(5) <> '-s' then WriteWord((i*2)+2,fs); // Add module to index.
    AddFile(fs,IntToStr(i)+'.tmp.cmp'); // Append module to main file.
    EvenFile; // Ensure modules are even-aligned.
    DeleteFile(IntToStr(i)+'.tmp.cmp'); // Delete module file.
    end;
  SaveFile(ParamStr(4)); // Save final file.

  endnow:
end.