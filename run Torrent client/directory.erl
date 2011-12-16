-module(directory).
-export([handle_directories/2,make_path/2,get_Dirs/2,create_directories/2,make_directories/2]).
-export([bins_to_list/2]).
-include("defs.hrl").
   %% gets a default path and a record of required information of files directories.
   handle_directories(Default_path,Data)->
    {FInfo_List,_}= Data#torrent.files,
    Dir_List = get_Dirs(FInfo_List,[]),
    Parent_path = Data#torrent.filename,
    make_directories(Default_path ++"/"++Parent_path,Dir_List)
   .
   %% Gets a parent directory and a list of directories of at least one file.
   make_directories(Parent_path,[Last_path])->
    create_directories(Parent_path,Last_path)
   ;
   make_directories(Parent_path,[Head|Tail])->
    create_directories(Parent_path,Head),
    make_directories(Parent_path,Tail)
   .
   %% gets a parent directory and a list of directories for a file,
   %% and creates this directory if does not exist.

   create_directories(Path,[_FName])->
  
     case filelib:is_dir(Path) of
       true ->
             Path;
       false ->
	     file:make_dir(Path),
	     Path
     end ;
   create_directories(Path,[Head|Tail])->
     case filelib:is_dir(Path) of
       true ->
             create_directories(Path ++ "47" ++ Head,Tail);
       false ->
	     file:make_dir(Path),
	     create_directories(Path ++ "47" ++ Head,Tail)
     end   
    .
 

   %% Gets a list of lists, extracts head of each list and places them in another list.
   get_Dirs([[Bins|_]],Db) ->
        List  = directory:bins_to_list(Bins,[]),
        Db ++ [List];
   get_Dirs ([[Bins|_]|Tail],Db)->
        List  = directory:bins_to_list(Bins,[]),
    get_Dirs (Tail, Db ++ [List]).

   bins_to_list([Bin],Db)->
         List  =  binary:bin_to_list(Bin),
         Db ++ [List];
   bins_to_list([Bin|Tail],Db)->
        List  =  binary:bin_to_list(Bin),  
        bins_to_list(Tail,Db ++ [List]).

   %% Gets a list, creates a path by its elements
   make_path([],_)->
     [];
   make_path([Last_Dirbin],Path)->
      Dir = binary:bin_to_list(Last_Dirbin),
    Path ++ "/" ++ Dir ;
   make_path([Dirbin|Tail],[])->
     Dir = binary:bin_to_list(Dirbin),
    make_path( Tail,  Dir);
   make_path([Dirbin|Tail],Path)->
     Dir = binary:bin_to_list(Dirbin),
    make_path( Tail, Path ++ "/" ++ Dir) .
    
