-module(record_operation).
-export([is_multiple/1, get_PieceNum/1, get_Piece_Length/1 ,get_LPiece_Length/1,files_dict/3,get_FileName/1]).
-record (torrent,{filename,files,number_of_pieces,piece_length}).  %% This is for test, and later should be trasfered to the hrl. file
-record (files_data,{filename,path,size,passed_bytes}).


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
     Rec#torrent.number_of_pieces .

   get_FileName(Rec)->
     Rec#torrent.filename
   .
   get_LPiece_Length(Rec)->
    Prev = get_PieceNum(Rec)-2,
    get_filesSize(Rec)- (Prev * get_Piece_Length(Rec)) .

   get_Piece_Length(Rec)->
    Rec#torrent.piece_length .
   
   get_filesSize(Rec)->
    Files = Rec#torrent.files,
    lists:sum(get_tails(Files,[])) .
   get_tails([[_,Size]],Db)->
    Db ++ [Size];
   get_tails([[_|Size]|Tail],Db)->
     get_tails(Tail ,Db ++ [Size]) .

  %% returns files dictionary , key: numbers , value: record of each file information
   files_dict([[DirList,Size]],Dict,N)->  % Base case 
    [FileName|_] = lists:reverse(DirList),
    Path = directory:make_path(DirList -- FileName),
    {ok,Rec1} = dict:find(N-1,Dict), 
    Passed_bytes = (Rec1#files_data.passed_bytes)+ (Rec1#files_data.size),
    Rec2 = #files_data{filename = FileName, path = Path , size = Size , passed_bytes = Passed_bytes },
    dict:store(N,Rec2,Dict) ; 
   
   files_dict([[DirList,Size]|Tail], Dict, 1)->
    [FileName|_] = lists:reverse(DirList),
    Path = directory:make_path(DirList -- FileName), 
    Passed_bytes = 0 ,
    Rec2 = #files_data{filename = FileName, path = Path , size = Size , passed_bytes = Passed_bytes },
    files_dict(Tail,dict:store(1,Rec2,Dict),2)  
    ;
   files_dict([[DirList,Size]|Tail], Dict, N)->
    [FileName|_] = lists:reverse(DirList),
    Path = directory:make_path(DirList -- FileName),
    {ok,Rec1} = dict:find(N-1,Dict), 
    Passed_bytes = (Rec1#files_data.passed_bytes)+ (Rec1#files_data.size),
    Rec2 = #files_data{filename = FileName, path = Path , size = Size , passed_bytes = Passed_bytes },
    files_dict(Tail,dict:store(N,Rec2,Dict),N+1)
    .
