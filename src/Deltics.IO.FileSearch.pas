
{$i deltics.io.filesearch.inc}

  unit Deltics.IO.FileSearch;


interface

  uses
    Deltics.IO.FileSearch.Interfaces;


  type
    FileSearch = class
      class function InCurrentDir: IFileSearch;
      class function InFolder(const aValue: String): IFileSearch; overload;
      class function OnPATH: IFileSearch; overload;
      class function OnPath(const aValue: String): IFileSearch; overload;
    end;


implementation

  uses
    SysUtils,
    Windows,
    Deltics.IO.FileSearch.Implementation_;



{ FileSearch }

  class function FileSearch.InCurrentDir: IFileSearch;
  begin
    result := TFileSearch.Create(GetCurrentDir);
  end;


  class function FileSearch.InFolder(const aValue: String): IFileSearch;
  begin
    result := TFileSearch.Create(aValue);
  end;



  class function FileSearch.OnPATH: IFileSearch;
  var
    path: String;
  begin
    path    := GetEnvironmentVariable('PATH');
    result  := TFileSearch.Create(path);
  end;


  class function FileSearch.OnPath(const aValue: String): IFileSearch;
  begin
    result := TFileSearch.Create(aValue);
  end;



end.
