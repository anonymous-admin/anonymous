-module(record_operation).
-export([is_multiple/1, get_PieceNum/1, get_Piece_Length/1 ,get_LPiece_Length/1,files_dict/4,get_FileName/1]).
-export([get_pieces/1,findN/3,get_filesSize/1]).
-include("defs.hrl").  %% This is for test, and later should be trasfered to the hrl. file
-record (files_data,{filename,path,size,passed_bytes}).
     
  %% Gets record, returns the pieces
  get_pieces(Rec)->
   Rec#torrent.pieces
  .   
  %% Gets a record, checks if the field "files" has any special value.
   is_multiple(Rec)->
    case Rec#torrent.files of
     novalue  ->
	    false;
	_     ->
            true
    end.
    
  %% gets a torrent record and returns the value of the number_of_pieces.
   get_PieceNum(Rec)->
    ( Rec#torrent.number_of_pieces ).

   get_FileName(Rec)->
     Rec#torrent.filename
   .
   get_LPiece_Length(Rec)->   %%  it is  needed for testing
    PrevIndex = get_PieceNum(Rec)-1,
    get_filesSize(Rec)- (PrevIndex * get_Piece_Length(Rec)) .
   



   get_Piece_Length(Rec)->
   (Rec#torrent.piece_length) .
   
   get_filesSize(Rec)->
   {Files, _} = Rec#torrent.files,
    get_sum(Files,0) .
  
  get_sum([List],Sum)->
    Sum  + hd(lists:reverse(List));
   get_sum([List|Tail],Sum)->
     get_sum(Tail ,Sum + hd(lists:reverse(List))).
 
  %% returns files dictionary , key: numbers , value: record of each file information
   files_dict(ParentDir,[[DirBins,Size]],Dict,1)->  % Base case 
  %  io:format("in the filesDict~n"),
    [BinFileName|_] = lists:reverse(DirBins),
    FileName = binary:bin_to_list(BinFileName),
  %   io:format("FileName: ~p~n", [FileName]), 
    DirList = DirBins -- [BinFileName],
    Path = directory:make_path(DirList,[]),
  %  io:format("Path: ~p~n" ,[Path]), 
    Passed_bytes = 0,
  %  io:format("Passedbytes: ~p~n",[Passed_bytes]),
    case Path of 
     [] ->
        Rec2 = #files_data{filename = FileName, path =  ParentDir  , size = Size , passed_bytes = Passed_bytes},
        dict:store(1,Rec2,Dict) ; 
     _  ->

        Rec2 = #files_data{filename = FileName, path = ParentDir++"/"++Path , size = Size , passed_bytes = Passed_bytes },
	    dict:store(1,Rec2,Dict)
	    
        end  ;
   files_dict(ParentDir,[[DirBins,Size]],Dict,N)->  % Base case 
  %  io:format("in the filesDict~n"),
    [BinFileName|_] = lists:reverse(DirBins),
    FileName = binary:bin_to_list(BinFileName),
  %   io:format("FileName: ~p~n", [FileName]), 
    DirList = DirBins -- [BinFileName],
    Path = directory:make_path(DirList,[]),
 %   io:format("Path: ~p~n" ,[Path]),
    {ok,Rec1} = dict:find(N-1,Dict), 
    io:format("Rec1: ~p~n",[Rec1]),
    Passed_bytes = (Rec1#files_data.passed_bytes)+ (Rec1#files_data.size),
  %  io:format("Passedbytes: ~p~n",[Passed_bytes]),
    case Path of 
     [] ->
        Rec2 = #files_data{filename = FileName, path =  ParentDir  , size = Size , passed_bytes = Passed_bytes},
        dict:store(N,Rec2,Dict) ; 
     _  ->

        Rec2 = #files_data{filename = FileName, path = ParentDir++"/"++Path , size = Size , passed_bytes = Passed_bytes },
	    dict:store(N,Rec2,Dict)
	    
        end  ; 
   
   files_dict(ParentDir,[[DirBins,Size]|Tail], Dict, 1)->
  %  io:format("in the filesDict"),
    [BinFileName|_] = lists:reverse(DirBins),
    FileName = binary:bin_to_list(BinFileName),
    DirList = DirBins -- [BinFileName],
    Path = directory:make_path(DirList,[]), 
 %    io:format("FileName: ~p~n, DirList: ~p~n, Path: ~p~n", [FileName,DirList,Path]), 
    Passed_bytes = 0 ,
    case Path of
    [] ->
      Rec2 = #files_data{filename = FileName, path =  ParentDir  , size = Size , passed_bytes = Passed_bytes},
      files_dict(ParentDir,Tail,dict:store(1,Rec2,Dict),2) ;
    _ ->
  
      Rec2 = #files_data{filename = FileName, path = ParentDir++"/"++Path , size = Size , passed_bytes = Passed_bytes },
	    files_dict(ParentDir,Tail,dict:store(1,Rec2,Dict),2)
	    
     end
    ;
   files_dict(ParentDir,[[DirBins,Size]|Tail], Dict, N)->
  %  io:format("in the files_dict"),
    [BinFileName|_] = lists:reverse(DirBins),
  %  io:format("after reverse"),
    FileName = binary:bin_to_list(BinFileName),
    DirList = DirBins -- [FileName],
  %  io:format("before make path"),
    Path = directory:make_path(DirList,[]),
  %  io:format("after make path"),
    {ok,Rec1} = dict:find(N-1,Dict),
  %  io:format("FileName: ~p~n, DirList: ~p~n, Path: ~p~n, Rec1: ~p~n", [FileName,DirList,Path,Rec1]), 
    Passed_bytes = (Rec1#files_data.passed_bytes)+ (Rec1#files_data.size),
    case Path of 
	[] ->
	 Rec2 = #files_data{filename = FileName, path = ParentDir , size = Size , passed_bytes = Passed_bytes},
	    files_dict(ParentDir,Tail,dict:store(N,Rec2,Dict),N+1);
	_ ->
    Rec2 = #files_data{filename = FileName, path = (ParentDir++"/"++Path) , size = Size , passed_bytes = Passed_bytes},
	    files_dict(ParentDir,Tail,dict:store(N,Rec2,Dict),N+1)
	    
       end
    .

   findN(Dict,N,Sposition)->
     {ok, Rec} =  dict:find(N,Dict), 
          case (Rec#files_data.passed_bytes + Rec#files_data.size) > Sposition of 
            true ->  
	     N	  ;
	    false ->
	     findN(Dict,N+1,Sposition)
          end
       .
