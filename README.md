# Deltics.IO.FileSearch

Provides a fluent Api for searching for a file or files in a folder, subfolders or even in parent
folders, matching a specified filename or pattern.

This example demonstates searching for instances of files called `README.md` in the folder
`c:\dev\src` or in any subfolders or parent folders of that folder:


```
  var
    files: IStringList;
  begin
    FileSearch.InFolder('c:\dev\src')
      .Subfolders
      .ParentFolders
      .Filename('README.md')
      .Yielding.Files(files)
      .Execute;

    ..
  end;
```

At least one filename **MUST** be specified or the search will not yield any results.  To search
in the current directory, the convenience method `InCurrentDir` may be used:

```
   FileSearch.InCurrentDir
```

One or more Filename may be specified to search for, using wildcard patterns as required.  For
example, to search for `mp4` and `mkv` files in a folder `d:\media` and any subfolders:

```
   var
     movies: IStringList;
   begin
     FileSearch.InFolder('d:\media')
       .Filename('*.mp4')
       .Filename('*.mkv')
       .Subfolders
       .Yielding.Files(movies)
       .Execute;

     ..
   end;
```


## Recursive Search (Sub-Folders and Parent Folders)

The default behaviour of FileSearch is non-recursive.  That is, it will return only files and
folders in the specified folder(s) and not in any sub-folders.

To include sub-folders in the search include `Subfolders` before `Execute`ing.  Sub-folder searchs
are conducted in **ALL** folders in turn.  That is, if two folders are added to be searched, the
first folder and it's subfolders are searched, before the second folder and its subfolders are
searched.

To include parent folders in the search, include `ParentFolders` before `Execute`ing.  Regardless
of whether children are being recursed, parent folder searches do not include any sub-folders of
those parent folders.

Parent folders are searched only after all folders and sub-folders have been searched.

These methods may be called parameterless or with a boolean parameter to set the
required behaviour.  Calling the parameterless methods is equiavalent to
passing **TRUE** to the parameterised method.

**NOTE:** When searching sub-folders or parent folders, the `Folders` yield will contain _only_
those folders that match the specified filename pattern(s), _not_ all folders that were searched.


## Yields

There are four possible yields from a FileSearch:

1. Count - yields the total count of files and folders that match the specified filename(s)
2. Files - yields a stringlist of files that match the specified filename(s)
3. Folders - yields a stringlist of folders that match the specified filename(s)
4. Filename - yields the **first** filename (which may be a folder) that satisfies the file search

As many of these yields may be requested as required.  Note that if only the `Filename` yield is
requested, then the search will stop on the first filename or folder that satisfies the search.

Requesting multiple yields of the same type results in the last yield requested being honoured and
the earlier yield ignored.

```
  var
    filesA, filesB: IStringList;
    first: String;
  begin
     Directory.OfCurrentDir
       .Yielding.Files(filesA)
       .Yielding.Files(filesB)
       .Yielding.Filename(first)
       .Execute;

     // first will contain the first matching file/folder
     // filesA will be NIL
     // filesB will contain all matching filenames
  end;
```

When specifiying `Files` and `Folders` yields, if an uninitialised interface reference (NIL) is
provided then the search will create a stringlist for you, to hold the yield.

If you specify an existing stringlist, the yields will be added to current contents of that
existing stringlist.
