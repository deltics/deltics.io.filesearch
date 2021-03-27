
{$i deltics.io.filesearch.inc}

  unit Deltics.IO.FileSearch.Implementation_;


interface

  uses
    Deltics.InterfacedObjects,
    Deltics.StringLists,
    Deltics.IO.FileSearch.Interfaces;


  type
    PStringList = ^IStringList;


    TFileSearch = class(TComInterfacedObject, IFileSearch,
                                              IFileSearchYields)
      function IFileSearch.Filename = SearchFilename;
      function IFileSearchYields.Filename = YieldFilename;
    public // IFileSearch
      function SearchFilename(const aValue: String): IFileSearch;
      function InFolder(const aValue: String): IFileSearch;
      function OnPath(const aValue: String): IFileSearch;
      function ParentFolders: IFileSearch; overload;
      function ParentFolders(const aValue: Boolean): IFileSearch; overload;
      function Subfolders: IFileSearch; overload;
      function Subfolders(const aValue: Boolean): IFileSearch; overload;
      function Execute: Boolean;
      function Yielding: IFileSearchYields;

    public // IFileSearchYields
      function Count(var aValue: Integer): IFileSearch;
      function YieldFilename(var aValue: String): IFileSearch;
      function Files(var aList: IStringList): IFileSearch;
      function Folders(var aList: IStringList): IFileSearch;

    private
      fFilenames: StringArray;
      fFolders: StringArray;
      fHits: Integer;
      fRecurseChildren: Boolean;
      fRecurseParents: Boolean;
      fRecursive: Boolean;

      fCountDest: PInteger;
      fFilenameDest: PString;
      fFilesDest: PStringList;
      fFoldersDest: PStringList;
    public
      constructor Create(const aPath: String);
      property Hits: Integer read fHits;
    end;



implementation

  uses
    SysUtils,
    Deltics.IO.Path;



  type
    TFilepathFn = function(const aPath: String; const aFilename: String): String;


  function NonRecursiveFilePath(const aPath: String; const aFilename: String): String;
  begin
    result := aFilename;
  end;


  function RecursiveFilePath(const aPath: String; const aFilename: String): String;
  begin
    result := Path.Append(aPath, aFilename);
  end;





  constructor TFileSearch.Create(const aPath: String);
  begin
    inherited Create;

    OnPath(aPath)
  end;


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
            fFilenameDest^  := Path.Append(aPath, rec.Name);
            done            := NOT Assigned(fCountDest)
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
        fFilesDest^ := TStringList.CreateManaged;

      files := fFilesDest^;
    end;

    if fFoldersDest <> NIL then
    begin
      if fFoldersDest^ = NIL then
        fFoldersDest^ := TStringList.CreateManaged;

      folders := fFoldersDest^;
    end;

    if fRecursive then
      FilePath := RecursiveFilePath
    else
      FilePath := NonRecursiveFilePath;

    for i := 0 to High(fFolders) do
    begin
      for j := 0 to High(fFilenames) do
      begin
        Find(fFolders[i], fFilenames[j], fRecurseChildren);

        if done then
          BREAK;
      end;

      if done then
        BREAK;
    end;

    if fRecurseParents and NOT done then
    begin
      for i := 0 to High(fFolders) do
      begin
        dir := fFolders[i];
        while Path.Branch(dir, dir) do;
        begin
          for j := 0 to High(fFilenames) do
          begin
            Find(dir, fFilenames[j], FALSE);

            if done then
              BREAK;
          end;

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


  function TFileSearch.SearchFilename(const aValue: String): IFileSearch;
  var
    i: Integer;
  begin
    for i := 0 to High(fFilenames) do
      if fFilenames[i] = aValue then
        EXIT;

    SetLength(fFilenames, Length(fFilenames) + 1);
    fFilenames[High(fFilenames)] := aValue;

    result := self;
  end;


  function TFileSearch.InFolder(const aValue: String): IFileSearch;
  var
    i: Integer;
    dir: String;
  begin
    if Pos(';', aValue) > 0 then
    begin
      OnPath(aValue);
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

    result := self;
  end;


  function TFileSearch.OnPath(const aValue: String): IFileSearch;
  var
    i: Integer;
    path: String;
    dir: String;
    split: Boolean;
  begin
    if Pos(';', aValue) <= 0 then
    begin
      InFolder(aValue);
      EXIT;
    end;

    path := Trim(aValue);
    while TRUE do
    begin
      split := FALSE;

      for i := 1 to Length(path) do
      begin
        split := path[i] = ';';
        if split then
          BREAK;
      end;

      if split then
      begin
        dir := Copy(path, 1, i - 1);
        Delete(path, 1, i);
        InFolder(dir);
      end
      else
      begin
        InFolder(path);
        BREAK;
      end;
    end;
  end;


  function TFileSearch.ParentFolders: IFileSearch;
  begin
    fRecurseParents := TRUE;
    fRecursive      := TRUE;
    result := self;
  end;


  function TFileSearch.ParentFolders(const aValue: Boolean): IFileSearch;
  begin
    fRecurseParents := aValue;
    fRecursive      := fRecurseChildren or fRecurseParents;
    result := self;
  end;


  function TFileSearch.Subfolders: IFileSearch;
  begin
    fRecurseChildren  := TRUE;
    fRecursive        := TRUE;
    result := self;
  end;


  function TFileSearch.Subfolders(const aValue: Boolean): IFileSearch;
  begin
    fRecurseChildren  := aValue;
    fRecursive        := fRecurseChildren or fRecurseParents;
    result := self;
  end;



  function TFileSearch.Yielding: IFileSearchYields;
  begin
    result := self;
  end;


  function TFileSearch.Count(var aValue: Integer): IFileSearch;
  begin
    fCountDest := @aValue;
    result := self;
  end;


  function TFileSearch.Files(var aList: IStringList): IFileSearch;
  begin
    fFilesDest := @aList;
    result := self;
  end;


  function TFileSearch.Folders(var aList: IStringList): IFileSearch;
  begin
    fFoldersDest := @aList;
    result := self;
  end;


  function TFileSearch.YieldFilename(var aValue: String): IFileSearch;
  begin
    fFilenameDest := @aValue;
    result := self;
  end;




end.
