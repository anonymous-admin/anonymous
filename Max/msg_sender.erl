-module(msg_sender).

-compile(export_all).

register_nickname(Nickname) ->
    Pid = spawn(msg_sender, handle_messages, [Nickname]),
    msg_controller:register_nick(Nickname, Pid).
	
unregister_nickname(Nickname) ->
    msg_controller:unregister_nick(Nickname).
   
init_reciever(ProcessName) ->
	msg_controller ! {register_nick, ProcessName, self()},
	msg_controller ! {subscribe,ProcessName,[{status, 13}]},
	handle_messages(ProcessName).	
	
init_sender(ProcessName) ->
	msg_controller ! {register_nick, ProcessName, self()},
	msg_controller ! {notify,status,{13,deleted}},
	handle_messages(ProcessName).	

handle_messages(ProcessName) ->
    receive
	{notify, Event, {Id, Var}} ->
	    io:format("received ~p~n", [Event]),
	    io:format("event ~p received for Tid: ~p~n", [Var, Id]),
	    handle_messages(ProcessName);
	stop ->
	    ok
    end.
	


start_router() ->
    msg_controller:start().
