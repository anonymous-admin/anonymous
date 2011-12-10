-module(intermediate).
-export([start_moderate/0,moderate/1]).

  start_moderate()->
   register(intermediate,spawn(intermediate,moderate,[dict:new()])),
   gen_server:cast( msg_controller ,{subscribe,intermediate, [{torrent_info, -1},{set_block, -1},{get_block, -1},{available_pieces, -1},{torrent_status, -1}]})
  .
  
  moderate(TorDict) ->
  

   receive 
     % msgs from blackboard 
     {notify,torrent_info,{Torrent_id,DataRec}}->
			 Pid = file_handler:start_main(Torrent_id,DataRec),
	                 Pid ! start ,
                         moderate(dict:store(Torrent_id,Pid,TorDict));
     {notify,set_block,{Tid,[Index,Begin,Block]}}->
         {ok, Pid} = dict:find(Tid,TorDict),
          Pid ! {set_block,Index,Begin,Block} ,
          moderate(TorDict)
        ;
     {notify,get_block,{_Tid,[_Peid,_Index,_Begin,_Length]}}->
       ok ;
    
   % {notify,torrent_status,{Tid,opened}}->  Maybe the torrent parser must receive it.
   %	   ;

     {notify,torrent_status,{Tid,resumed}}->
         {ok, Pid} = dict:find(Tid,TorDict),
          Pid ! resume ,
          moderate(TorDict)
           ;
     {notify,torrent_status,{Tid,stopped}}->
          {ok, Pid} = dict:find(Tid,TorDict),
          Pid ! stop ,
          moderate(dict:erase(Tid,TorDict))
    	   ;
     {notify,torrent_status,{Tid,paused}}->
         {ok, Pid} = dict:find(Tid,TorDict),
          Pid ! pause ,
          moderate(TorDict)
    	   ;
     {notify,torrent_status,{Tid,deleted}}->
      moderate(dict:erase(Tid,TorDict))
    	   ;
       
     % Msgs from main processes
     {notify,available_pieces,{Tid,[Indexes]}}->
      msg_controller !  {notify,available_pieces,{Tid,[Indexes]}} ,
      moderate(TorDict)		
   end
  .
