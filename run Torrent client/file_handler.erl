-module(file_handler).
-export([start_main/3,main/4]).
-include("defs.hrl").


   start_main(Tid,DataRec,Default_Path)->
     spawn (file_handler,main,[Tid,{DataRec,null},dict:new(),Default_Path])
   .

  main(Tid,{DataRec,Pid},PieceDict,Default_Path)-> 
 %%      process_flag(trap_exit,true),
       Is_multiple =  record_operation:is_multiple(DataRec),  % number of files is checked.

  receive

    start -> %% intermediate sends this msg as soon as it spawns this process
    
      %% The single or multiple mode is handled and loop again.
      case Is_multiple of
 
       false ->    
       ok ;
       true ->
    %% structure of the directories is created and loop again.
      directory:handle_directories(Default_Path,DataRec)
    % io:format("in file_handler, directories were created~n") 
       end ,
      NewPid = spawn(data_handler,handle_blocks,[DataRec,dict:new(),self(),Is_multiple]),
      link(NewPid),     
      NewPid ! make_dict ,
      main(Tid,{DataRec,NewPid},PieceDict,Default_Path);                 

    pause -> 
      main(Tid,{DataRec,Pid},PieceDict,Default_Path);  
 
    resume ->  
      main(Tid,{DataRec,Pid},PieceDict,Default_Path);

    {set_blocks,BlockList} -> 
  %    io:format("file_handler got set_block ~n"),
      Pid ! {set_blocks,Default_Path, BlockList},
  %    io:format("file_handler sent set_block to data_handler ~n"),
      main(Tid,{DataRec,Pid},PieceDict,Default_Path);
    {get_block,[Peid,Index,Begin,Length]}->
      %% io:format("file_handler got get_blocks ~n"),
      %% io:format("in file_handler:Peid: ~p~n",[Peid]),
      %% io:format("in file_handler:Index: ~p~n",[Index]),
      %% io:format("in file_handler:Begin: ~p~n",[Begin]),
      %% io:format("in file_handler:Length: ~p~n",[Length]),
      Pid ! {get_block,{Default_Path,[Peid,Index,Begin,Length]}},
    %%  io:format("get_block was sent to datahandler ~n "),
     main(Tid,{DataRec,Pid},PieceDict,Default_Path);
    {block,[Peid,Index,Begin,Block]}->
     gen_server:cast(intermediate, {notify,block,{Tid,[Peid,Index,Begin,Block]}}),
  %%   io:format("file_handler sent blcok to intermediate ~n"),
     main(Tid,{DataRec,Pid},PieceDict,Default_Path);   
    stop ->
      Pid ! stop , 
    stopped ;

    {ready_piece, Index} ->
        %  io:format("file_handler got ready_piece~n"),
	%  io:format("PieceDict: ~p~n",[PieceDict]),
    	 case dict:find (Tid,PieceDict) of  
    		 {ok, Value} ->
                  NewDict = dict:store(Tid,Value ++ [Index],PieceDict), 
	%%	  io:format("file_handler had already some ready_pieces ~n"),
                  gen_server:cast(intermediate , {notify,available_pieces,{Tid,Value ++ [Index]}}),
                  main(Tid,{DataRec,Pid},NewDict,Default_Path);
                  error ->
                  NewDict = dict:store(Tid,[Index],PieceDict),
	%%	  io:format("file_handler did not have any ready_pieces ~n"),
                  gen_server:cast(intermediate , {notify,available_pieces,{Tid,[Index]}}),  
        %%        io:format("file_handler sent available_pieces to intermediate"),
                  main(Tid,{DataRec,Pid},NewDict,Default_Path)
                  end ;
    {'EXIT' , _FromP, normal } ->
           ok;
    {'EXIT' , _FromP, _ } ->
         NewPid = spawn(data_handler,handle_blocks,[DataRec,dict:new(),PieceDict,self(),Is_multiple]),
         link(NewPid),     
         NewPid ! make_dict ,
         main(Tid,{DataRec,NewPid},PieceDict,Default_Path) 
  end
    .
