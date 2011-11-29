-module(msg_controller).

-define(SERVER, msg_controller).

-compile(export_all).

start() ->
  server_util:start(?SERVER, {msg_controller, route_messages, [dict:new(),dict:new()]}),
  msg_logger:start().

stop() ->
	server_util:stop(?SERVER),
	msg_logger:stop().

% send_chat_message(Addressee, MessageBody) ->
%	?SERVER!{send_chat_msg, Addressee, MessageBody}.

%register_nick(ProcessName, ProcessesPid) ->
%	?SERVER!{register_nick, ProcessName, ProcessesPid}.

%unregister_nick(ProcessName) ->
%	?SERVER!{unregister_nick, ProcessName}.


subscribe_processIntrest([],_ProcessName, Interests) ->
	Interests;


subscribe_processIntrest([{Interest, Id}|T], ProcessName, Interests) ->
	NewDict = dict:append(Interest,{ProcessName, Id}, Interests),
	io:format(" dic updated"),
	subscribe_processIntrest(T, ProcessName, NewDict).
	
notify_processes([], _, _, _) ->	
	ok;

notify_processes([{Subscriber,TorrentId}|T], TorrentId, Event, Var) ->
	Subscriber ! {notify, Event, {TorrentId, Var}},%CANT SEND MESSAGE TO NONREGISTERED PROCESS AAAAAAAAAAAAAAAAAAAAAAAAAA
	io:format("event sent to ~p,~n", [Subscriber]),
	notify_processes(T, TorrentId, Event, Var);

notify_processes([{_,Id}|T], TorrentId, Event, Var) ->	
	notify_processes(T, TorrentId, Event, Var).


route_messages(Processes,Interests) ->
  receive
	
	{notify,Event,{Id,Var}} ->
		io:format("received msg ~p,~n ", [Event]),
		case dict:is_key(Event,Interests) of
			true ->
				io:format(" event found ~w~n", [Event]),			     
				notify_processes(dict:fetch(Event,Interests), Id, Event, Var);		
			false ->
				io:format("no subscriber found for event ~p,~n", [Event])
		end;		
		
	
	{subscribe,ProcessName,[{Interest, Id}|T]} ->
		io:format("received msg subscribe"),		
		case dict:find(ProcessName, Processes) of
			{ok, _ProcessesPid} ->
				route_messages(Processes,subscribe_processIntrest([{Interest, Id}|T], ProcessName, Interests));		
			error->
				io:format("no process id found for ~p~n", [ProcessName]),
				route_messages(Processes,Interests)	
		end;		
	

	{send_chat_msg, ProcessName, MessageBody} ->
      case dict:find(ProcessName, Processes) of
		{ok, ProcessesPid} ->
			ProcessesPid ! {printmsg, MessageBody};
	error ->
	  msg_logger:save_message(ProcessName, MessageBody),
	  io:format("Archived message for ~p~n", [ProcessName])
      end,
      route_messages(Processes, Interests);
    {register_nick, ProcessName, ProcessesPid} ->
	io:format("received msg register_nick"),
	  Messages = msg_logger:find_messages(ProcessName),
      lists:foreach(fun(Msg) -> ProcessesPid ! {printmsg, Msg} end, Messages),
      route_messages(dict:store(ProcessName, ProcessesPid, Processes),Interests);
    {unregister_nick, ProcessName} ->
      case dict:find(ProcessName, Processes) of
	{ok, ProcessesPid} ->

	  ProcessesPid ! stop,
	  route_messages(dict:erase(ProcessName, Processes),Interests);
	error ->
	  io:format("Error! Unknown client: ~p~n", [ProcessName]),
	  route_messages(Processes,Interests)
      end;
    shutdown ->
      io:format("Shutting down~n");
    Oops ->
      io:format("Warning! Received: ~p~n", [Oops]),
      route_messages(Processes,Interests)
  end.
