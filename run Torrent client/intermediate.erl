-module(intermediate).
-export([start_intermediate/0,init/1,handle_cast/2,stop_procs/2,code_change/3,handle_call/3,handle_info/2]).
-export([terminate/2]).
-behaviour(gen_server).
-include("defs.hrl").

  start_intermediate()->
   gen_server:start_link({local,intermediate},intermediate,{dict:new(),null,null},[])  % null1 = Path, null2 = torrent_info
  .
  
  init({Dict,null,null})->
  process_flag(trap_exit, true), 
  gen_server:cast(msg_controller,{subscribe,intermediate,[{default_path,-1},{torrent_info,-1},{set_blocks,-1},{get_block,-1},{torrent_status,-1}]}),
  {ok,{Dict,null,null}}
    .
 
     % msgs from blackboard  
     handle_cast({notify,default_path,{_Torrent_id,DefPath}},{TorDict,null,null})->                              
          io:format("iiiiiiiiiiiiiiiiin intermediate: default_path was received, no torrent_info"),
         {noreply , {TorDict,DefPath,null}}
            ; 
    handle_cast({notify,default_path,{_Torrent_id,DefPath}},{TorDict,null,[Tid,DataRec]})->
            Pid = file_handler:start_main(Tid,DataRec,DefPath),
            link(Pid),
            Pid ! start ,
            io:format("already had a torrent_info rec, path received, directories created"),
            NewDict = dict:store(Tid,Pid,TorDict),
           {noreply , {NewDict,null,DataRec}};  
     handle_cast({notify,default_path,{_Torrent_id,DefPath}},{TorDict,DefPath,DataRec})-> % when user changes the path
                             
          io:format("iiiiiiiiiiiiiiiiin intermediate: user changed the path"),
          {noreply , {TorDict,DefPath,DataRec}}
           ; 
     handle_cast({notify,torrent_info,{Torrent_id,DataRec}},{TorDict,null,null})->
        {noreply , {TorDict,null,[Torrent_id,DataRec]}};

     handle_cast({notify,torrent_info,{Torrent_id,DataRec}},{TorDict,Path,null})->
    
            Pid = file_handler:start_main(Torrent_id,DataRec,Path),
            link(Pid),
            Pid ! start ,
            io:format("already had a path, info received, directories created"),
            NewDict = dict:store(Torrent_id,Pid,TorDict),
	   {noreply , {NewDict,Path,DataRec}};

     handle_cast({notify,set_blocks,{Tid,BlockList}},{TorDict,_P,_R})->
           io:format("intermediate got set_block ~n"),
           {ok, Pid} = dict:find(Tid,TorDict),
           Pid ! {set_blocks,BlockList} ,
           io:format(" set_block sent from intermediate ~n"),
           {noreply,{TorDict,_P,_R}}
           ;
     handle_cast({notify,get_block,{Tid,[Peid,Index,Begin,Length]}},{TorDict,_P,_R})->
            io:format("intermediate got get_block ~n"),
            io:format("Tid: ~p~n", [Tid]),
            io:format("Peid: ~p~n", [Peid]),
            io:format("index: ~p~n", [Index]),
            io:format("Begin: ~p~n", [Begin]),
            io:format("Length: ~p~n", [Length]),
           {ok,Pid} = dict:find(Tid,TorDict),  
           Pid ! {get_block,[Peid,Index,Begin,Length]},
           io:format("intermediate sent get_block to pid: ~p ~n", [Pid]),
           {noreply,{TorDict,_P,_R}}  
           ;
     handle_cast({notify,torrent_status,{Tid,resumed}},{TorDict,_P,_R})->
           {ok, Pid} = dict:find(Tid,TorDict),
           Pid ! resume ,
           {noreply,{TorDict,_P,_R}}
           ;
     handle_cast({notify,torrent_status,{Tid,stopped}},{TorDict,_P,_R})->
           {ok, Pid} = dict:find(Tid,TorDict),
           Pid ! stop ,
           NewDict = dict:erase(Tid,TorDict),
           {noreply,{NewDict,_P,_R}}
    	   ;
     handle_cast({notify,torrent_status,{Tid,paused}}, {TorDict,_P,_R})->
           {ok, Pid} = dict:find(Tid,TorDict),
           Pid ! pause ,
           { noreply, {TorDict,_P,_R}}
    	   ;
     handle_cast({notify,torrent_status,{Tid,deleted}},{TorDict,_P,_R})->
           {ok, Pid} = dict:find(Tid,TorDict),
           Pid ! stop,
           NewDict = dict:erase(Tid,TorDict),
           {noreply,{NewDict,_P,_R}}    
           ;
      handle_cast({notify,torrent_status,{_Tid,opened}},{TorDict,_P,_R})->
           {noreply,{TorDict,_P,_R}}    
           ;
      handle_cast({notify,torrent_status,{_Tid,started}},{TorDict,_P,_R})->
           {noreply,{TorDict,_P,_R}}    
           ;
     handle_cast(terminate,{TorDict,_P,_R})->
           Keys = dict:fetch_keys(TorDict),
           stop_procs(Keys,TorDict),
           {stop,normal,{TorDict,_P,_R}}
           ;      

     % Msgs from main processes
     handle_cast({notify,block,{Tid,[Peid,Index,Begin,Block]}},{TorDict,_P,_R})->
          % io:format("intermediate got block from file_handler"),
           gen_server:cast( msg_controller  ,{notify,block,{Tid,[Peid,Index,Begin,Block]}}),   %% has to be gen_server
          % io:format("block was sent to msg_controller "),
           {noreply,{TorDict,_P,_R}}  
            ;
     handle_cast({'EXIT',TerPid,normal},{TorDict,_P,_R})->
           Keys = dict:fetch_keys(TorDict),
           NewDict = find_Tid(TerPid,Keys,TorDict),
           {noreply,{NewDict,_P,_R}}     
            ;
     handle_cast({'EXIT',TerPid,_},{TorDict,_P,_R})->          
           Keys = dict:fetch_keys(TorDict),
           NewDict = find_rec(TerPid,Keys,TorDict),
           {noreply,{NewDict,_P,_R}}       
            ;
     handle_cast({notify,available_pieces,{Tid,IndexesList}},{TorDict,_P,_R})->
      %     io:format("intermediate got available_pieces"),
      gen_server:cast( msg_controller , {notify,available_pieces,{Tid,IndexesList}}), 
           {noreply,{TorDict,_P,_R}} .

     terminate(_Reason, _TorDict) ->
           gen_server:cast(intermediate,terminate) .		
 
     stop_procs([Tid],TorDict)->
           {ok,{Pid,_,_}} = dict:find(Tid,TorDict),
           Pid ! stop ;
     stop_procs([Tid|Tail],TorDict)->
           {ok,{Pid,_,_}} = dict:find(Tid,TorDict),
           Pid ! stop , 
           stop_procs(Tail,TorDict).

     find_rec(Pid,[TorId|Tail],TorDict)->
           case dict:find(TorId,TorDict) of 
             {ok,{Pid,DefPath,TorRec}} ->
                            Pid2 = file_handler:start_main(TorId,TorRec,DefPath),
                            link(Pid2),
	                    case record_operation:is_multiple(TorRec) of 
				false ->
				    directory:set_wdir(DefPath);
                                true ->
				    ok
				      end,	      
			    NewDic = dict:erase(TorId,TorDict),
                            dict:store(TorId,{Pid2,DefPath,NewDic});
        _ ->

        find_rec(Pid,Tail,TorDict)
               end   .
    

    find_Tid(Pid,[TorId|Tail],TorDict)->
         case dict:find(TorId,TorDict) of
           {ok , {Pid,_,_}} ->
	      dict:erase(TorId,TorDict); 
	  _ ->
              find_Tid(Pid,Tail,TorDict)
      end .

  % just not to get warning !!!!
   code_change(_OldV,_State,_Extra)->
      ok .
   handle_call(_Request,_From,_state)->
      ok .
   handle_info(_Info, _State)->
      ok .
