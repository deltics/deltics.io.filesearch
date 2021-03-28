
{$i deltics.io.filesearch.inc}

  unit Deltics.IO.FileSearch.Implementation_;


interface

  uses
    Deltics.InterfacedObjects,
    Deltics.StringLists,
    Deltics.StringTypes,
    Deltics.IO.FileSearch.Interfaces;


  type
    PStringList = ^IStringList;


    TFileSearch = class(TComInterfacedObject, IFileSearch,
                                              IFileSearchYields)
      function IFileSearch.Filename = SearchFilename;
      function IFileSearchYields.Filename = YieldFilename;
    public // IFileSearch
      function AllFiles: IFileSearch;
      function CurrentDir(const aReplaceExisting: Boolean = FALSE): IFileSearch;
      function SearchFilename(const aValue: String; const aReplaceExisting: Boolean = FALSE): IFileSearch;
      function Folder(const aValue: String; const aReplaceExisting: Boolean = FALSE): IFileSearch;
      function OnPATH(const aReplaceExisting: Boolean = FALSE): IFileSearch;
      function ParentFolders: IFileSearch; overload;
      function ParentFolders(const aValue: Boolean): IFileSearch; overload;
      function Subfolders: IFileSearch; overload;
      function Subfolders(const aValue: Boolean): IFileSearch; overload;
      function Execute: Boolean;
      function Yielding: IFileSearchYields;

    public // IFileSearchYields
      function Count(var aValue: Integer): IFileSearch;
      function YieldFilename(var aValue: String): IFileSearch; overload;
      function Files(var aList: IStringList; const aReplacingContents: Boolean = FALSE): IFileSearch;
      function Folders(var aList: IStringList; const aReplacingContents: Boolean = FALSE): IFileSearch;
      function FullyQualified: IFileSearch;

    private
      fFilenames: StringArray;
      fFolders: StringArray;
      fFullyQualified: Boolean;
      fHits: Integer;
      fRecurseChildren: Boolean;
      fRecurseParents: Boolean;
      fRecursive: Boolean;

      fCountDest: PInteger;
      fFilenameDest: PString;
      fFilesDest: PStringList;
      fFoldersDest: PStringList;
      fReplaceFiles: Boolean;
      fReplaceFolders: Boolean;
    public
      property Hits: Integer read fHits;
    end;


  procedure SplitMulti(const aString: String; var aValues: StringArray);


implementation

  uses
    SysUtils,
//    Windows,
    Deltics.IO.Path;


  procedure SplitMulti(const aString: String; var aValues: StringArray);
  var
    i: Integer;
    remaining: String;
    startPos: Integer;
    value: String;
    valueIdx: Integer;
  begin
    remaining := Trim(aString);

    if Length(remaining) = 0 then
    begin
      SetLength(aValues, 0);
      EXIT;
    end;

    if Pos(';', remaining) = 0 then
    begin
      SetLength(aValues, 1);
      aValues[0] := remaining;
      EXIT;
    end;

    SetLength(aValues, Length(remaining) div 2);

    startPos  := 1;
    valueIdx  := 0;

    for i := 1 to Length(remaining) do
    begin
      if remaining[i] <> ';' then
        CONTINUE;

      value     := Trim(Copy(remaining, startPos, i - startPos));
      startPos  := i + 1;

      if value <> '' then
      begin
        aValues[valueIdx] := value;
        Inc(valueIdx);
      end;
    end;

    value := Trim(Copy(remaining, startPos, (Length(remaining) - startPos) + 1));
    if value <> '' then
    begin
      aValues[valueIdx] := value;
      Inc(valueIdx);
    end;

    SetLength(aValues, valueIdx);
  end;



  type
    TFilepathFn = function(const aPath: String; const aFilename: String): String;


  function FilenameOnly(const aPath: String; const aFilename: String): String;
  begin
    result := aFilename;
  end;


  function QualifiedFilePath(const aPath: String; const aFilename: String): String;
  begin
    result := Path.Append(aPath, aFilename);
  end;




{ TFileSearch ------------------------------------------------------------------------------------ }

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Execute: Boolean;
  var
    done: Boolean;
    files: IStringList;
    folders: IStringList;
    FilePath: TFilePathFn;

    procedure Find(const aPath: String; const aPattern: String; const aRecursive: Boolean);
    var
      i: Integer;
      rec: TSearchRec;
      subfolders: IStringList;
    begin
      subfolders := TStringList.CreateManaged;
      if FindFirst(Path.Append(aPath, aPattern), faAnyFile, rec) = 0 then
      try
        repeat
          if Path.IsNavigation(rec.Name) then
            CONTINUE;

          if ((rec.Attr and faDirectory) <> 0) then
          begin
            if Assigned(folders) then
              folders.Add(FilePath(aPath, rec.Name));
          end
          else if Assigned(files) then
            files.Add(FilePath(aPath, rec.Name));

          Inc(fHits);

          if (fHits = 1) and Assigned(fFilenameDest) then
          begin
            fFilenameDest^  := FilePath(aPath, rec.Name);

            done  := NOT Assigned(fCountDest)
                 and NOT Assigned(fFilesDest)
                 and NOT Assigned(fFoldersDest);
          end;

        until done or (FindNext(rec) <> 0);

      finally
        FindClose(rec);
      end;

      if NOT aRecursive then
        EXIT;

      if (FindFirst(Path.Append(aPath, '*.*'), faDirectory, rec) = 0) then
      try
        repeat
          if Path.IsNavigation(rec.Name) then
            CONTINUE;

          if (rec.Attr and faDirectory) <> 0 then
            subfolders.Add(Path.Append(aPath, rec.Name))

        until FindNext(rec) <> 0;

      finally
        FindClose(rec);
      end;

      for i := 0 to Pred(subfolders.Count) do
        Find(subfolders[i], aPattern, TRUE);
    end;

  var
    i, j: Integer;
    dir: String;
  begin
    fHits := 0;
    done  := FALSE;

    if fFilesDest <> NIL then
    begin
      if fFilesDest^ = NIL then
        fFilesDest^ := TStringList.CreateManaged
      else if fReplaceFiles then
        (fFilesDest^).Clear;

      files := fFilesDest^;
    end;

    if fFoldersDest <> NIL then
    begin
      if fFoldersDest^ = NIL then
        fFoldersDest^ := TStringList.CreateManaged
      else if fReplaceFolders then
        (fFoldersDest^).Clear;

      folders := fFoldersDest^;
    end;

    if fRecursive or fFullyQualified or (Length(fFolders) > 1) then
      FilePath := QualifiedFilePath
    else
      FilePath := FilenameOnly;

    for i := 0 to High(fFolders) do
    begin
      dir := Path.Absolute(fFolders[i]);

      if Length(fFilenames) > 0 then
      begin
        for j := 0 to High(fFilenames) do
        begin
          Find(dir, fFilenames[j], fRecurseChildren);

          if done then
            BREAK;
        end;
      end
      else
        Find(dir, '*.*', fRecurseChildren);

      if done then
        BREAK;
    end;

    if fRecurseParents and NOT done then
    begin
      for i := 0 to High(fFolders) do
      begin
        dir := Path.Absolute(fFolders[i]);

        while Path.Branch(dir, dir) do
        begin
          if Length(fFilenames) > 0 then
          begin
            for j := 0 to High(fFilenames) do
            begin
              Find(dir, fFilenames[j], FALSE);

              if done then
                BREAK;
            end;
          end
          else
            Find(dir, '*.*', FALSE);

          if done then
            BREAK;
        end;

        if done then
          BREAK;
      end;
    end;

    if Assigned(fCountDest) then
      fCountDest^ := fHits;

    result := fHits > 0;
  end;

{--------------------------------------------------------------------------------------------------}
// NOTE:  Debugging is disabled for all methods following this point.  These methods are for
//         configuring the search  and are unlikley to be of interest.  If they are suspected
//         of some fault and require debugging, simply add the required additional $DEFINE to
//         your project settings.
{--------------------------------------------------------------------------------------------------}

{$debuginfo OFF}
{$ifdef debug_DelticsIOFileSearchConfiguration}
  {$debuginfo ON}
{$endif}

{--------------------------------------------------------------------------------------------------}

  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.SearchFilename(const aValue: String;
                                      const aReplaceExisting: Boolean): IFileSearch;
  var
    i: Integer;
    patterns: StringArray;
  begin
    result := self;

    if aReplaceExisting then
      SetLength(fFilenames, 0);

    if Pos(';', aValue) > 0 then
    begin
      SplitMulti(aValue, patterns);

      for i := 0 to High(patterns) do
        SearchFilename(patterns[i]);

      EXIT;
    end;

    for i := 0 to High(fFilenames) do
      if fFilenames[i] = aValue then
        EXIT;

    SetLength(fFilenames, Length(fFilenames) + 1);
    fFilenames[High(fFilenames)] := aValue;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Folder(const aValue: String;
                              const aReplaceExisting: Boolean): IFileSearch;
  var
    i: Integer;
    dir: String;
    dirs: StringArray;
  begin
    result := self;

    if aReplaceExisting then
      SetLength(fFolders, 0);

    if Pos(';', aValue) > 0 then
    begin
      SplitMulti(aValue, dirs);

      for i := 0 to High(dirs) do
        Folder(dirs[i]);

      EXIT;
    end;

    dir := Trim(aValue);
    if dir = '' then
      EXIT;

    for i := 0 to High(fFolders) do
      if fFolders[i] = dir then
        EXIT;

    SetLength(fFolders, Length(fFolders) + 1);
    fFolders[High(fFolders)] := dir;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.OnPATH(const aReplaceExisting: Boolean): IFileSearch;
  begin
    result := self;

    Folder(GetEnvironmentVariable('PATH'), aReplaceExisting);
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.ParentFolders: IFileSearch;
  begin
    fRecurseParents := TRUE;
    fRecursive      := TRUE;
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.ParentFolders(const aValue: Boolean): IFileSearch;
  begin
    fRecurseParents := aValue;
    fRecursive      := fRecurseChildren or fRecurseParents;
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Subfolders: IFileSearch;
  begin
    fRecurseChildren  := TRUE;
    fRecursive        := TRUE;
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Subfolders(const aValue: Boolean): IFileSearch;
  begin
    fRecurseChildren  := aValue;
    fRecursive        := fRecurseChildren or fRecurseParents;
    result := self;
  end;



  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Yielding: IFileSearchYields;
  begin
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.AllFiles: IFileSearch;
  begin
    SearchFilename('*.*', TRUE);
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Count(var aValue: Integer): IFileSearch;
  begin
    fCountDest := @aValue;
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.CurrentDir(const aReplaceExisting: Boolean): IFileSearch;
  begin
    Folder(GetCurrentDir, aReplaceExisting);
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Files(var   aList: IStringList;
                             const aReplacingContents: Boolean): IFileSearch;
  begin
    fFilesDest    := @aList;
    fReplaceFiles := aReplacingContents;

    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.Folders(var   aList: IStringList;
                               const aReplacingContents: Boolean): IFileSearch;
  begin
    fFoldersDest    := @aList;
    fReplaceFolders := aReplacingContents;

    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.FullyQualified: IFileSearch;
  begin
    fFullyQualified := TRUE;
    result := self;
  end;


  { - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - }
  function TFileSearch.YieldFilename(var aValue: String): IFileSearch;
  begin
    fFilenameDest := @aValue;
    result := self;
  end;




end.
