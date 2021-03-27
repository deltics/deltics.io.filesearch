
{$i deltics.io.filesearch.inc}

  unit Deltics.IO.FileSearch.Interfaces;


interface

  uses
    Deltics.StringLists;


  type
    IFileSearch = interface;
    IFileSearchYields = interface;


    IFileSearchYields = interface
    ['{B3978FCB-856F-4EA8-9780-4C4C8360D99E}']
      function Count(var aValue: Integer): IFileSearch;
      function Filename(var aValue: String): IFileSearch;
      function Files(var aList: IStringList): IFileSearch;
      function Folders(var aList: IStringList): IFileSearch;
      function FullyQualified: IFileSearch;
    end;


    IFileSearch = interface
    ['{6B271D6D-5037-45EC-9A85-29BF0695CDBC}']
      function Filename(const aValue: String): IFileSearch;
      function InFolder(const aValue: String): IFileSearch;
      function OnPath(const aValue: String): IFileSearch;
      function ParentFolders: IFileSearch; overload;
      function ParentFolders(const aValue: Boolean): IFileSearch; overload;
      function Subfolders: IFileSearch; overload;
      function Subfolders(const aValue: Boolean): IFileSearch; overload;
      function Execute: Boolean;
      function Yielding: IFileSearchYields;
    end;



implementation

end.
