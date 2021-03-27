
{$apptype CONSOLE}

  program test;

uses
  Deltics.Smoketest,
  Deltics.IO.FileSearch in '..\src\Deltics.IO.FileSearch.pas',
  Deltics.IO.FileSearch.Interfaces in '..\src\Deltics.IO.FileSearch.Interfaces.pas',
  Deltics.IO.FileSearch.Implementation_ in '..\src\Deltics.IO.FileSearch.Implementation_.pas',
  Test.FileSearch in 'Test.FileSearch.pas';

begin
  TestRun.Test(FileSearchTests);
end.
