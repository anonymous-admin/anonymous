-module(directory).
-export([handle_directories/2,set_wdir/1,make_path/2,t/0]).
-record(torrent,{filename = "parent", files = [[["second","ssecond","2.docx"],123],[["first","ffirst","1.txt"],456]]}).
 
  %% This is for test.
    t()->
     handle_directories("C:/Users/Mo/Desktop/mtask", #torrent{filename = "parent"})
  . 
   %% gets a default path and a record of required information of files directories.
   handle_directories(Default_path,Data)->
    set_wdir(Default_path),
    FInfo_List = Data#torrent.files,
    Dir_List = get_Dirs(FInfo_List,[]),
    Parent_path = Data#torrent.filename,
    make_directories(Parent_path,Dir_List)
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
             create_directories(Path ++ "\\" ++ Head,Tail);
       false ->
	     file:make_dir(Path),
	     create_directories(Path ++ "\\" ++ Head,Tail)
     end   
    .
   %% Gets a path and sets the working directory to it.
   set_wdir(Path)->
     file:set_cwd(Path).

   %% Gets a list of lists, extracts head of each list and places them in another list.
   get_Dirs([[List|_]],Db) ->
    Db ++ [List];
   get_Dirs ([[List|_]|Tail],Db)->
    get_Dirs (Tail, Db ++ [List]).


   %% Gets a list, creates a path by its elements
   make_path([],_)->
     [];
   make_path([Last_Dir],Path)->
    Path ++ "\\" ++ Last_Dir ;
   make_path([Dir|Tail],[])->
    make_path( Tail,  Dir);
   make_path([Dir|Tail],Path)->
    make_path( Tail, Path ++ "\\" ++ Dir) .
    
