
{$i deltics.io.filesearch.inc}

  unit Deltics.IO.FileSearch;


interface

  uses
    Deltics.IO.FileSearch.Interfaces;


  type
    IFileSearch = Deltics.IO.FileSearch.Interfaces.IFileSearch;


  function FileSearch: IFileSearch;


implementation

  uses
    SysUtils,
    Windows,
    Deltics.IO.FileSearch.Implementation_;



  function FileSearch: IFileSearch;
  begin
    result := TFileSearch.Create;
  end;



end.
