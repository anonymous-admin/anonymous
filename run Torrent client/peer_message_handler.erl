%%Author : Massih
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
    after 15000 ->
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
	    <<Bitfield_length:32>> = list_to_binary(lists:sublist(Msg,69,4)),
	    Bitfield = lists:sublist(Msg,73,Bitfield_length),
	    PID ! {bitfield,Bitfield},
	    %%PID ! send_interest,
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
	[0,0,0,1,0|_Rest] ->
	    PID ! get_choke,
	    if
		length(Msg) > 5 ->
		    New_Msg = lists:nthlist(5,Msg),
		    check_messages(New_Msg,Buff,PID);
		true ->
		    msg_handler([],PID)
	    end;
	[0,0,0,5|Rest] ->
	    %%io:format("the real piece index is : ~w~n",[list_to_binary(lists:sublist(lists:nthtail(1,Rest),4))]),
	    <<Piece_index:32>> = list_to_binary(lists:sublist(lists:nthtail(1,Rest),4)),
	    if 
		length(Msg) > 9 ->
		    New_Msg = lists:nthtail(9,Msg),
		    PID ! {peer_have_piece,Piece_index},
		    check_messages(New_Msg,Buff,PID);
		true ->
		    PID ! send_interest,
		    msg_handler([],PID)
	    end;
	[0,0,0,0|_R] ->
	    PID ! get_keep_alive,
	    if 
		length(Msg) > 4 ->
		    New_Msg = lists:nthtail(4,Msg),
		    check_messages(New_Msg,Buff,PID);
		true ->
		    msg_handler([],PID)
	    end;
	[0,0,0,3,9|_R]->
	    port;
	_ ->
	    <<Length:32>> = list_to_binary(lists:sublist(Msg,4)),
	    io:format("msg length : ~w         block length : ~w ",[length(Msg),Length]),
	    Identifier = lists:nth(5,Msg),
	    if
		 Identifier == 7 ->
		    <<Index:32>> = list_to_binary(lists:sublist(Msg,6,4)),
		    <<Begin:32>> = list_to_binary(lists:sublist(Msg,10,4)),
		    Block = list_to_binary(lists:sublist(Msg,14,Length - 9)),
		    PID ! {recieved_piece,Index,Begin,Block},
		    if 
			length(Msg) > Length+4 ->
			    New_Msg = lists:nthtail(4+Length,Msg),
			    check_messages(New_Msg,Buff,PID);
			true ->
			    io:format("rest is ~w",[Msg]),
			    msg_handler([],PID)
		    end;
		true ->
		    io:format("other message is : ~p~n",[Msg])
	    end
    end.

%%check_length(Msg,Length)->
%%    ok.
    
		
	    
	    
	
    
	
