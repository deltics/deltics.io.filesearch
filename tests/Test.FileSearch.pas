
{$i deltics.inc}

  unit Test.FileSearch;


interface

  uses
    Deltics.Smoketest;

  type
    FileSearchTests = class(TTest)
      procedure SearchingPATH;
    {$ifNdef _CICD}
      procedure SearchingPATHLookingForFirstResult;
    {$endif}
      procedure WorksAsExpected;
    end;



implementation

  uses
    Deltics.IO.FileSearch,
    Deltics.IO.FileSearch.Interfaces,
    Deltics.IO.FileSearch.Implementation_,
    Deltics.InterfacedObjects,
    Deltics.StringLists;


{ FileSearchTests }

  procedure FileSearchTests.SearchingPATH;
  var
    count: Integer;
  begin
    FileSearch.OnPATH
      .Filename('cmd.exe')
      .Yielding.Count(count)
      .Execute;

    Test('count').Assert(count).Equals(1);
  end;


{$ifNdef _CICD}
  procedure FileSearchTests.SearchingPATHLookingForFirstResult;
  var
    count: Integer;
    s: String;
    search: IFileSearch;
    impl: TFileSearch;
  begin
    FileSearch.OnPATH
      .Filename('dcc32.exe')
      .Yielding.Filename(s)
      .Yielding.Count(count)
      .Execute;

    Test('count').Assert(count).GreaterThan(1);

    search := FileSearch.OnPATH;
    search.Filename('dcc32.exe')
      .Yielding.Filename(s)
      .Execute;

    impl := TFileSearch((search as IInterfacedObject).AsObject);
    count := impl.Hits;

    Test('count').Assert(count).Equals(1);
  end;
{$endif}


  procedure FileSearchTests.WorksAsExpected;
  var
    count: Integer;
    files, ogFiles: IStringList;
    folders: IStringList;
  begin
    count   := -1;
    ogFiles := TStringList.CreateManaged;
    files   := ogFiles;

    FileSearch.InCurrentDir
      .Subfolders
      .ParentFolders
      .Filename('*.exe')
      .Yielding.Count(count)
      .Yielding.Files(files)
      .Yielding.Folders(folders)
      .Execute;

    Test('count').Assert(count).GreaterThanOrEquals(0);
    Test('files').Assert(files).IsAssigned;
    Test('files = ogFiles').Assert(files).Equals(ogFiles);
    Test('folders').Assert(folders).IsAssigned;
  end;




end.
