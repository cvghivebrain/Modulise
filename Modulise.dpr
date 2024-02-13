program PModulise;

{$APPTYPE CONSOLE}

uses
  Classes,
  SysUtils,
  FileFunc in 'FileFunc.pas';

var
  i, modsize, modcount, lastmodsize, modcountwrite: integer;
  noindex, nolast, useshort, aligneven, actualcount: boolean;

label endnow;

begin
  { Program start }

  if ParamCount < 4 then
    begin
    WriteLn('Usage: modulise.exe {compressor} {module_size} {input_file} {output_file}');
    goto endnow; // End program if run without parameters.
    end;
  if not FileExists(ParamStr(1)) then
    begin
    WriteLn(ParamStr(1)+' not found.');
    goto endnow; // End if compressor doesn't exist.
    end;
  if not TryStrToInt(ParamStr(2),modsize) then
    begin
    WriteLn(ParamStr(2)+' not valid.');
    goto endnow; // End if module size is invalid.
    end;
  if not FileExists(ParamStr(3)) then
    begin
    WriteLn(ParamStr(3)+' not found.');
    goto endnow; // End if file doesn't exist.
    end;
  if ParamCount >= 5 then
    for i := 5 to ParamCount do
      begin
      if ParamStr(i) = '-s' then useshort := true;
      if ParamStr(i) = '-noindex' then noindex := true;
      if ParamStr(i) = '-nolast' then nolast := true;
      if ParamStr(i) = '-aligneven' then aligneven := true;
      if ParamStr(i) = '-actualcount' then actualcount := true;
      end;

  modsize := StrToInt(ParamStr(2)); // Set size of modules.
  LoadFile(ParamStr(3));
  lastmodsize := fs mod modsize;
  modcount := fs div modsize;
  if lastmodsize > 0 then Inc(modcount);
  if actualcount then modcountwrite := modcount
    else modcountwrite := modcount-1; // Header will show mod count minus 1 by default.
  WriteLn(IntToStr(modcount)+' modules to compress.');
  for i := 0 to modcount-1 do
    begin
    ClipFile(i*modsize,modsize,IntToStr(i)+'.tmp'); // Split module from main file.
    if not FileExists(IntToStr(i)+'.tmp') then WriteLn('Failed to create temp file.');
    RunCommand(ParamStr(1)+' '+IntToStr(i)+'.tmp'+' '+IntToStr(i)+'.tmp.cmp'); // Compress.
    if not FileExists(IntToStr(i)+'.tmp.cmp') then WriteLn('Failed to compress temp file.');
    DeleteFile(IntToStr(i)+'.tmp'); // Delete uncompressed module.
    end;
  NewFile(2); // Start a new file.
  if useshort then WriteWord(0,(modcountwrite shl 12)+lastmodsize) // Use short header.
  else
    begin
    WriteWord(0,modcountwrite);
    if not noindex then WriteWord(((modcount-1)*2)+2,0); // Create blank index.
    if not nolast then WriteWord(fs,lastmodsize); // Write size of last module.
    end;
  for i := 0 to modcount-1 do
    begin
    if not (useshort or noindex) then WriteWord((i*2)+2,fs); // Add module to index.
    AddFile(fs,IntToStr(i)+'.tmp.cmp'); // Append module to main file.
    if aligneven then EvenFile; // Ensure modules are even-aligned.
    DeleteFile(IntToStr(i)+'.tmp.cmp'); // Delete module file.
    end;
  SaveFile(ParamStr(4)); // Save final file.

  endnow:
end.