-module(file_handler).
-export([start_main/2,main/3]).
-record(torrent,{default_path,filename = "parent", files = [[["second","ssecond","2.docx"],123],[["first","ffirst","1.txt"],456]],number_of_pieces}).    %% this is for test, and should be trasfered to the hrl file.

   start_main(Tid,DataRec)->
     spawn (file_handler,main,[Tid,DataRec,0,dict:new()])
   .

  main(Tid,DataRec,PieceDict)->  %%%%%  other receive statements
                                 %%%%%  must be added for the case of data-handler termination and... .

       Is_multiple = record_operation:is_multiple(DataRec),  % number of files is checked.
       Default_path = DataRec#torrent.default_path,
  receive

    start -> %% intermediate sends this msg as soon as it spawns this process
   
      %% The single or multiple mode is handled and loop again.
      case Is_multiple of
 
       false ->
        directory:set_wdir(Default_path);
       true ->
        %% structure of the directories is created and loop again.
        directory:handle_directories(Default_path,DataRec) 
      end ,
      
      register( Tid , spawn(data_handler,handle_blocks,[DataRec,dict:new(),PieceDict,self(),Is_multiple])), %% Is it ok to use Tid?
      link(Tid),     
      Tid ! make_dict ,
      main(Tid,DataRec,PieceDict);
       

    pause -> 
      main(Tid,DataRec,PieceDict);  
 
    resume ->  
      main(Tid,DataRec,PieceDict);

    {set_block,Index,Begin,Binary} -> 
      Tid ! {set_block,Default_path, Index,Begin,Binary},
      main(Tid,DataRec,PieceDict);
    stop -> 
    stopped ;

    {ready_piece, Index} ->
	 case dict:find (Tid,PieceDict) of  
		 {ok, Value} ->
                  NewDict = dict:store(Tid,Value ++ [Index],PieceDict),
                  intermediate ! {notify,available_pieces,{Tid,Value ++ [Index]}},
                  main(Tid,DataRec,NewDict);
                  error ->
                  NewDict = dict:store(Tid,[Index],PieceDict),
                  intermediate ! {notify,available_pieces,{Tid,[Index]}},
                  main(Tid,DataRec,NewDict)

         end       
    
  end
    .
