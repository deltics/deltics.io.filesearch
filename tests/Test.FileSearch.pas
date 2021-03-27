
{$i deltics.inc}

  unit Test.FileSearch;


interface

  uses
    Deltics.Smoketest;

  type
    FileSearchTests = class(TTest)
      procedure FullyQualifiedResults;
      procedure MultiPatternFilename;
      procedure SearchingPATH;
    {$ifNdef _CICD}
      procedure SearchingPATHLookingForFirstResult;
    {$endif}
      procedure SplitMultiResults;
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

  procedure FileSearchTests.FullyQualifiedResults;
  var
    filename: String;
  begin
    FileSearch.InCurrentDir
      .Filename('*.*')
      .Yielding.Filename(filename)
      .Execute;

    Test('filename').Assert(filename).DoesNotContain('\');

    FileSearch.InCurrentDir
      .Filename('*.*')
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
    FileSearch.InFolder('c:\windows')
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
