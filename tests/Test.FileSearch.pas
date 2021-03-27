
{$i deltics.inc}

  unit Test.FileSearch;


interface

  uses
    Deltics.Smoketest;

  type
    FileSearchTests = class(TTest)
      procedure FullyQualifiedResults;
      procedure MultiPatternFilename;
      procedure ReuseSearchAddingFilesContentInYield;
      procedure ReuseSearchAddingFoldersContentInYield;
      procedure ReuseSearchReplacingFilesContentInYield;
      procedure ReuseSearchReplacingFoldersContentInYield;
      procedure ReuseSearchReplacingSearchFilename;
      procedure ReuseSearchReplacingSearchFolder;
      procedure SearchingPATH;
    {$ifNdef _CICD}
      procedure SearchingPATHLookingForFirstResult;
    {$endif}
      procedure SplitMultiResults;
    end;



implementation

  uses
    Deltics.IO.FileSearch,
    Deltics.IO.FileSearch.Interfaces,
    Deltics.IO.FileSearch.Implementation_,
    Deltics.InterfacedObjects,
    Deltics.StringLists;


{ FileSearchTests }

  procedure FileSearchTests.FullyQualifiedResults;
  var
    filename: String;
  begin
    FileSearch.CurrentDir.AllFiles
      .Yielding.Filename(filename)
      .Execute;

    Test('filename').Assert(filename).DoesNotContain('\');

    FileSearch.CurrentDir.AllFiles
      .Yielding.Filename(filename)
      .Yielding.FullyQualified
      .Execute;

    Test('filename').Assert(filename).Contains('\');
  end;


  procedure FileSearchTests.MultiPatternFilename;
  var
    i: Integer;
    files: IStringList;
    foundDll: Boolean;
    foundExe: Boolean;
  begin
    FileSearch.Folder('c:\windows')
      .Filename('*.dll;*.exe')
      .Yielding.Files(files)
      .Execute;

    Test('files').Assert(files.Count).GreaterThan(0);

    foundDll  := FALSE;
    foundExe  := FALSE;

    for i := 0 to Pred(files.Count) do
    begin
      foundDll := foundDll or (Copy(files[i], Length(files[i]) - 2, 3) = 'dll');
      foundExe := foundExe or (Copy(files[i], Length(files[i]) - 2, 3) = 'exe');

      if foundDll and foundExe then
        BREAK;
    end;

    Test('dll+exe').Assert(foundDll and foundExe).IsTrue;
  end;


  procedure FileSearchTests.ReuseSearchAddingFilesContentInYield;
  var
    search: IFileSearch;
    files: IStringList;
    count: Integer;
  begin
    files := TStringList.CreateManaged;

    search := FileSearch.Yielding.Files(files);

    search.Folder('c:\windows').Execute;
    count := files.Count;

    Test('files.Count').Assert(count).GreaterThan(0);

    search.Execute;

    Test('files.Count = 2x count').Assert(files.Count).Equals(2 * count);
  end;


  procedure FileSearchTests.ReuseSearchAddingFoldersContentInYield;
  var
    search: IFileSearch;
    folders: IStringList;
    count: Integer;
  begin
    folders := TStringList.CreateManaged;

    search := FileSearch.Yielding.Folders(folders);

    search.Folder('c:\windows').Execute;
    count := folders.Count;

    Test('folders.Count').Assert(count).GreaterThan(0);

    search.Execute;

    Test('folders.Count = 2x count').Assert(folders.Count).Equals(2 * count);
  end;


  procedure FileSearchTests.ReuseSearchReplacingFilesContentInYield;
  var
    search: IFileSearch;
    files: IStringList;
    count: Integer;
  begin
    files := TStringList.CreateManaged;

    search := FileSearch.Yielding.Files(files, TRUE);

    search.Folder('c:\windows').Execute;
    count := files.Count;

    Test('files.Count').Assert(count).GreaterThan(0);

    search.Execute;

    Test('files.Count = count').Assert(files.Count).Equals(count);
  end;


  procedure FileSearchTests.ReuseSearchReplacingFoldersContentInYield;
  var
    search: IFileSearch;
    folders: IStringList;
    count: Integer;
  begin
    folders := TStringList.CreateManaged;

    search := FileSearch.Yielding.Folders(folders, TRUE);

    search.Folder('c:\windows').Execute;
    count := folders.Count;

    Test('folders.Count').Assert(count).GreaterThan(0);

    search.Execute;

    Test('folders.Count = count').Assert(folders.Count).Equals(count);
  end;


  procedure FileSearchTests.ReuseSearchReplacingSearchFilename;
  var
    search: IFileSearch;
    count: Integer;
    dllCount: Integer;
    exeCount: Integer;
  begin
    search := FileSearch.Folder('c:\windows');

    search.Filename('*.dll;*.exe').Yielding.Count(count).Execute;

    Test('count').Assert(count).GreaterThan(0);

    search.Filename('*.exe', TRUE).Yielding.Count(exeCount).Execute;

    Test('exeCount').Assert(exeCount).GreaterThan(0);

    search.Filename('*.dll', TRUE).Yielding.Count(dllCount).Execute;

    Test('dllCount').Assert(dllCount).GreaterThan(0);

    Test('dllCount + exeCount').Assert(dllCount + exeCount).Equals(count);
  end;


  procedure FileSearchTests.ReuseSearchReplacingSearchFolder;
  var
    search: IFileSearch;
    count: Integer;
    windowsCount: Integer;
    rootCount: Integer;
  begin
    search := FileSearch.Folder('c:\windows;c:\').AllFiles;

    search.Yielding.Count(count).Execute;
    Test('count').Assert(count).GreaterThan(0);

    search.Folder('c:\windows', TRUE).Yielding.Count(windowsCount).Execute;
    Test('windowsCount').Assert(windowsCount).GreaterThan(0);

    search.Folder('c:\', TRUE).Yielding.Count(rootCount).Execute;
    Test('rootCount').Assert(rootCount).GreaterThan(0);

    Test('windowsCount + rootCount').Assert(windowsCount + rootCount).Equals(count);
  end;


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


  procedure FileSearchTests.SplitMultiResults;
  var
    result: StringArray;
  begin
    SplitMulti('', result);
    Test('SplitMulti().length').Assert(Length(result)).Equals(0);

    SplitMulti(' ', result);
    Test('SplitMulti( ).length').Assert(Length(result)).Equals(0);

    SplitMulti('abc', result);
    Test('SplitMulti(abc).length').Assert(Length(result)).Equals(1);
    Test('SplitMulti(abc)[0]').Assert(result[0]).Equals('abc');

    SplitMulti('abc;def', result);
    Test('SplitMulti(abc;def).length').Assert(Length(result)).Equals(2);
    Test('SplitMulti(abc;def)[0]').Assert(result[0]).Equals('abc');
    Test('SplitMulti(abc;def)[1]').Assert(result[1]).Equals('def');

    SplitMulti(' abc ; 123 ; def ', result);
    Test('SplitMulti( abc ; 123 ; def ).length').Assert(Length(result)).Equals(3);
    Test('SplitMulti( abc ; 123 ; def )[0]').Assert(result[0]).Equals('abc');
    Test('SplitMulti( abc ; 123 ; def )[1]').Assert(result[1]).Equals('123');
    Test('SplitMulti( abc ; 123 ; def )[2]').Assert(result[2]).Equals('def');
  end;





end.
