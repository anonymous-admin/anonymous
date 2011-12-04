-module(peer_message_handler).
-export([start/1]).

start(PID)->
    spawn(fun()->msg_handler([],PID)end).
    

msg_handler(Messages,PID) ->
    receive
	stop ->
	    io:format("msghandler stopped correctly !!! ~n");
	Msg ->
	    io:format("msg rcv length ~w~n",[length(Msg)]),
	    msg_handler(Messages ++ Msg,PID)
    after 5000 ->
	    if
		length(Messages) > 0 ->
		    io:format("time out2 ~n"),
		    check_messages(Messages,[],PID);
		true ->
		    msg_handler(Messages,PID)
	    end
    end.
	    
	
check_messages(Msg,Buff,PID) ->
    %%io:format("the message length is : ~w~n and the message is : ~w~n",[length(Msg),Msg]),
    case Msg of
	[19,66,105,116|_Rest] ->
	    _Handshake_response = lists:sublist(Msg,68),
	    PID ! {handshake_response,_Handshake_response},
	    %io:format("handshake response is : ~w~n",[_Handshake_response]),
	    <<Bitfield_length:32>> = list_to_binary(lists:sublist(Msg,69,4)),
	    %io:format("bitfield length is : ~w~n",[Bitfield_length]),
	    Bitfield = lists:sublist(Msg,73,Bitfield_length),
	    PID ! {bitfield,Bitfield},
	    PID ! send_interest,
	    %io:format("bitfield is : ~w~n",[Bitfield]),
	    New_length = 72+Bitfield_length,
	    if 
		length(Msg) > New_length ->
		    New_buff = lists:nthtail(New_length,Msg),
		    io:format("remain is : ~w~n",[New_buff]),
		    check_messages(New_buff,Msg,PID);
		true ->
		  msg_handler([],PID)
	    end;
	[0,0,0,1,1|_Rest] ->
	    PID ! get_unchoke,
	    if
		length(Msg) > 5 ->
		    New_Msg = lists:nthlist(5,Msg),
		    check_messages(New_Msg,Buff,PID);
		true ->
		    msg_handler([],PID)
	    end;
	    %% if 
	    %% 	lists:nth(2,Status) == 0 ->
	    %% 	    gen_tcp:send(Socket,<<0,0,1,2>>),
	    %% 	    [_,_,A,B] =Status,
	    %% 	    check_message(Socket,R,Buff,PID,[0,1,A,B]);
	    %%    _->
		%%    ok
%	    end;
	[0,0,0,5|Rest] ->
	    <<Piece_index:32>> = list_to_binary(lists:sublist(lists:nthtail(1,Rest),4)),
	    if 
		length(Msg) > 9 ->
		    New_Msg = lists:nthtail(9,Msg),
		    PID ! {peer_have_piece,Piece_index},
		    check_messages(New_Msg,Buff,PID);
		true ->
		    msg_handler([],PID)
	    end;
	[0,0,0,0] ->
	    PID ! get_keep_alive,
	    msg_handler([],PID);	
	_ ->
	    <<Length:32>> = list_to_binary(lists:sublist(Msg,4)),
	    if 
		length(Msg) > Length ->
		    Index = lists:sublist(Msg,6,4),
		    Begin = lists:sublist(Msg,10,4),
		    Block = lists:sublist(Msg,14,Length - 9),
		    PID ! {recieved_piece,Index,Begin,Block};
		true ->
		    io:format("rest is ~w",[Msg])
	    end
    end.

		
	    
	    
	
    
	
