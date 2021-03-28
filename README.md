# Deltics.IO.FileSearch

Provides a fluent Api for searching for a file or files in a folder, subfolders or even in parent
folders, matching a specified filename or pattern.

This example demonstates searching for instances of files called `README.md` in the folder
`c:\dev\src` or in any subfolders or parent folders of that folder:


```
  var
    files: IStringList;
  begin
    FileSearch.Folder('c:\dev\src')
      .Subfolders
      .ParentFolders
      .Filename('README.md')
      .Yielding.Files(files)
      .Execute;

    ..
  end;
```

At least one folder **MUST** be specified or the search will not yield any results.  If no filename
is specified then the search will return all files (`*.*`).

Convenience methods are provided for specifying the current directory (`CurrentDir`) or to include
folders on the environment PATH variable (`OnPATH`).


## Re-Using Search Objects and COnfiguration

The `Filename` and all of the folder configuration methods support an optional `aReplaceExisting`
parameter.  This is `FALSE` by default, so that filenames or folders are _added_ to the current
search configuration.  If `TRUE` is specified instead, then any current configuration is replaced
by the configuration being added.

The `Files` and `Folders` yields similarly provide an optional `aReplacingContents` parameter that
determines whether search results are added to the existing contents of a specified list, or will
replace any existing content.

These optional paramters enable search objects to be re-used, for example when searching for
different files in the same set of folders or for the same file(s) in different folders.

```
  // Seach for JPEG files in the current directory and sub-folders, yielding the results
  //  in a 'files' stringlist, replacing the contents each time the search is executed.

   search := FileSearch.Filename('*.jpg;*.jpeg')
              .CurrentDir
              .SubFolders
              .Yielding.Files(files, TRUE);

   search.Execute;
   ..

  // Now repeat the same search but looking only for PNG files

   search.Filename('*.png', TRUE).Execute;

```

## Filename Patterns

As illustrated above, a `Filename` may be specified to search for using wildcard patterns as
required.  For example, to search for `mp4`, `mkv`, `avi` and `mov` files in a folder `d:\media`
and any subfolders.

Multiple filenames or patterns may be specified using a `;` delimiter:

```
   var
     movies: IStringList;
   begin
     FileSearch.Folder('d:\media')
       .Filename('*.mp4')
       .Filename('*.mkv')
       .Filename('*.avi;*.mov')
       .Subfolders
       .Yielding.Files(movies)
       .Execute;

     ..
   end;
```


## Recursive Search (Sub-Folders and Parent Folders)

The default behaviour of FileSearch is non-recursive.  That is, it will return only files and
folders in the specified folder(s) and not in any sub-folders.

To include sub-folders in the search include `SubFolders` before `Execute`ing.  Sub-folder searchs
are conducted in **ALL** folders in turn.  That is, if two folders are added to be searched, the
first folder and subfolders are searched, before the second folder and subfolders are
searched.

You may also include _parent_ folders in the search, by calling `ParentFolders`.  Parent folder
searches do not include any sub-folders of those parent folders, irrespective of the `SubFolders`
configuration.

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
     FileSearch.CurrentDir
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


## Fully Qualified Results (File path and Filename)

The results of a FileSearch will be formatted according to the following criteria:

* If more than one `Folder` is configured, results are fully qualified
* If `ParentFolders` or `SubFolders` are being searched, results are fully qualified
* If only one folder is being searched with both `ParentFolders` and `SubFolders` not set
  or set FALSE, then results are **NOT** fully qualified _(filename only, no path)_

If you wish to guarantee fully qualified results you can include the **FullyQualified** call on the
`Yielding` configuration:

```
  FileSearch.CurrentDir
    .Yielding.FullyQualified
    .Yielding.Files(files)
    .Execute;
```
