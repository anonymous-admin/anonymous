%%Author:Massih
%%Creation Date: 11-Nov-2011
-module(peers_interactor).
-export([init/1,start_link/1,terminate/2,handle_cast/2,handle_call/3]).
-export([test/0,handshake/1]).
-behaviour(gen_server).
-include("defs.hrl").

init(Data)->
    handshake(Data),
    {ok,Data}.

terminate(_Reason,Data)->
    ok.

start_link(Data)->
    gen_server:start_link(?MODULE,Data,[]).
%%M = [19,"bittorrent protocol",<<0.0.0.0.0.0.0.0 /binary>>,"%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A","edocIT00855481937666"],

handle_call(Request,_From,Data) ->
    {reply,null,Data}.

handle_cast(Request,Data)->
    {noreply,Data}.


handshake([Ip,Port])->
    Msg = list_to_binary([<<19>>,<<"BitTorrent protocol">>,
			  <<0,0,0,0,0,0,0,0>>,
			  <<22,113,38,65,158,241,132,180,236,143,179,202,70,90,183,254,209,151,81,154>>,
			  list_to_binary("-AZ4004-znmphhbrij37")]),
    Connection =  gen_tcp:connect(Ip,Port,[list,{active,true},{packet,0}]),
    case Connection of
	{ok,Socket}->
	    %%inet:setopts(Socket,[{packet,68}]),
	    put(am_interested,0),
	    put(am_choking,1),
	    put(peer_interested,0),
	    put(peer_choking,1),
	    put(peer_have_list,dict:new()),
	    PID = peer_message_handler:start(self()),
	    gen_tcp:send(Socket,Msg),
	    loop(Socket,-1,PID);
	%%receive {_,_,M}->io:format("handshake recieve -> ~w~n",[M])end,
						%receive_loop(Socket,0,0,0,0,[],-1);
	{error,Error} ->
	    gen_server:cast(logger,{peer_handshake_error,Error}),
	    undefined
    end.


receive_loop(Socket,Am_choking,Am_interested,P_choking,P_interested,Buff,Remain) ->
    receive	    	
	{tcp,_Socket,[0,0,0,0]} ->
	    io:format("recieve Keep alive~n",[]),
	    reply_peer(Socket,<<0,0,0,0>>),
	    receive_loop(Socket,0,0,0,0,Buff,0);
	{tcp,_Socket,[0]}->
	    io:format("recieve zero",[]);
	{tcp,_Socket,[0,0,0,1]}->
	    io:format("recieve one ~n",[]);
	{tcp,_Socket,[0,0,0,2]}->
	    io:format("recieve two ~n",[]);
	{tcp,_Socket,[0,0,0,3]}->
	    io:format("recieve zero",[]);
						%	{tcp,Socket,Msg} ->
						%	    %io:format("tcp message is ~w~n and size is ~w~n",[Msg,byte_size(Msg)]),
						%	    io:format("tcp message is ~w~n and size is ~w~n",[Msg,length(Msg)]),	    
						%	    receive_loop(Socket,0,0,0,0,[]);
	{tcp,_,P} ->
	    case lists:sublist(P,20) of
		[19]++"BitTorrent protocol" ->
		    %%io:format("first message length is ~w~n ",[P]),
		    Rest = lists:nthtail(68,P),
		    case length(Rest) of
			0->
			    receive_loop(Socket,0,0,0,0,Buff,Remain);
			_->
			    <<Bitfield_length:32>> = list_to_binary(lists:sublist(Rest,4)),
			    New_Buff = lists:nthtail(6,Rest),
			    io:format("handshake is done ~n bitfield remain length is : ~w~n  ",[(Bitfield_length-2)-length(New_Buff)]),
			    reply_peer(Socket,<<0,0,0,1,2>>),
			    receive_loop(Socket,0,0,0,0,New_Buff,(Bitfield_length-2)-length(New_Buff))
		    end;
		_ -> 
		    io:format("bitfield remain is : ~w~n and packet length is : ~w~n",[Remain,length(P)]),
		    case Remain of
			0->
			    case P of
				[0,0,0,0|Rest] ->
				    reply_peer(Socket,<<0,0,0,0,0>>);
				[0,0,0,1|Rest] ->
				    case hd(Rest) of
					0->
					    ok;
					1 ->
					    io:format("get UNCHOKE !!!!!~n send INTERESTED !!!!"),
					    reply_peer(Socket,<<0,0,0,1,2>>);
					2 ->
					    ok;
					3 ->
					    ok
				    end;
				[0,0,1,3|Rest] ->
				    case hd(Rest) of
					6 ->
					    ok;
					8 ->
					    ok
				    end
			    end,
			    io:format("bitfield completed  get this ~w~n",[P]),
			    receive_loop(Socket,0,0,0,0,Buff,0);
			-1->
			    <<Bitfield_length:32>> = list_to_binary(lists:sublist(P,4)),
			    receive_loop(Socket,0,0,0,0,Buff,check_bitfield(Bitfield_length,P,Socket)-2);
			_ ->
			    receive_loop(Socket,0,0,0,0,Buff,check_bitfield(Remain,P,Socket))
		    end
	    end;
	{tcp_closed,Socket} ->
	    gen_server:cast(logger,{peer_connection_closed}),
	    receive_loop(Socket,0,0,0,0,[],0);
	_Other ->
	    io:format("other message is ~w~n",[_Other]),
	    receive_loop(Socket,0,0,0,0,[],0)
    after 60000 ->
	    timeout
    end.


check_bitfield(Remain,Msg,Socket)->
    case Remain < length(Msg) of
	true ->
	    Rest = lists:nthtail(Remain,Msg),
	    io:format("after bitfield is :~w~n",[Rest]),
	    msg_handler(Rest,Socket),
	    %%<<Piece_index:32>> = list_to_binary(lists:sublist(lists:nthtail(5,Rest),4)),
	    %%reply_peer(Socket,<<0,0,0,13,6,Piece_index,0>>),
	    0;
	false ->
	    New_Remain = Remain - length(Msg),
	    io:format("Its not finished wait for next receive !~n",[]),
	    New_Remain
    end.


reply_peer(Socket,Message)->
    gen_tcp:send(Socket,Message).

msg_handler([],Socket)->
    ok;
msg_handler([0,0,0,0|_],Socket) ->
    keepAlive;
msg_handler([0,0,0,1|Rest],Socket) when hd(Rest) == 0->
    choke;
msg_handler([0,0,0,1|Rest],Socket) when hd(Rest) == 1->
    unchoke;
msg_handler([0,0,0,1|Rest],Socket) when hd(Rest) == 2->
    intrested;
msg_handler([0,0,0,1|Rest],Socket) when hd(Rest) == 3->
    notIntrested;
msg_handler([0,0,0,5|Rest],Socket) ->
    Piece_index = lists:sublist(lists:nthtail(1,Rest),4),
    gen_tcp:send(Socket,<<0,0,0,13,6,Piece_index:32/binary,0:32,32768:32>>),
    io:format("send request for ~w~n",[Piece_index]),
    msg_handler(lists:nthtail(5,Rest),Socket);
msg_handler([255,255,255,255|T],Socket) ->
    msg_handler(T,Socket).


%%io:format("the rest is :~w~n and bit length is :~w~n and buff is :~w~n",[Rest,Bitfield_length,New_Buff]),
%%inet:setopts(Socket,[{packet,(Bitfield_length-length(Buff))}]),
%%inet:setopts(Socket,[{packet,0}]),


test()->
    URL = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A&peer_id=-AZ4004-znmphhbrij37&port=6881&downloaded=10&left=1588&event=started&numwant=12",
    inets:start(),
    {ok,Result} = httpc:request(URL),
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = parser:decode(list_to_binary(Body)),
    [Interval,Seeds,Leechers,Peers]=torrent_interpreter:get_tracker_response_info(Decoded_Body),
    [IP,PORT,_PID] = hd(Peers),
    io:format("connecting to ip: ~w~n in port : ~w~n",[binary_to_list(IP),PORT]),
    handshake([binary_to_list(IP),PORT]).


loop(Socket,Remain,PID)->
    receive 
	{tcp,_,Msg} ->
	    %io:format("message is ~p~n",[Msg]),
	    PID ! Msg ,
	    loop(Socket,Remain,PID);
	    %%messages_loop(Socket,Msg,Remain);
	{tcp_closed,_R} ->
	    io:format("CLOSED !!!!!!!! ~w~n",[_R]),
	    gen_server:cast(logger,{peer_connection_closed});
	{handshake_response,Handshake_response}->
	    io:format("handshake response is : ~w~n",[Handshake_response]),
	    loop(Socket,Remain,PID);
	{bitfield,Bitfield} ->
	    io:format("bitfield recieved and saved !!! ~n"),
	    %%put(bitfield,Bitfield),
	    loop(Socket,Remain,PID);	    
	send_interest ->
	    send_interest(Socket),
	    loop(Socket,Remain,PID);
	get_unchoke ->
	    io:format("get unchoke !!!~n"),
	    put(am_choking,0),
	    send_interest(Socket),
	    %%A = get(peer_have_list),
	    %%B = dict:fetc(A),
	    send_request([hd(dict:to_list(get(peer_have_list)))],Socket),
	    io:format("pieces are ~w~n",[dict:to_list(get(peer_have_list))]),
	    loop(Socket,Remain,PID);
	get_keep_alive ->
	    gen_tcp:send(Socket,<<0,0,0,0>>),
	    loop(Socket,Remain,PID);
	{peer_have_piece,Piece_index} ->
	    Dict = get(peer_have_list),
	    Dict2 = dict:append(Piece_index,[],Dict),
	    put(peer_have_list,Dict2),
	    loop(Socket,Remain,PID);
	{recieved_piece,Index,Begin,Block} ->
	    io:format("*************Piece recieved index is :~p     begin is : ~p~n block length is :~p~n",[Index,Begin,Block]);
	_Other ->
	    io:format("receive unknown message from a peer !!! ~n~w~n",[_Other]),
	    loop(Socket,Remain,PID)
    after 120000 ->
	    PID ! stop,
	    io:format("time out  !!!~n and all dic info is ~w~n",[erase()]),
	    gen_tcp:close(Socket)
    end.

send_interest(Socket)->
    case get(am_interested) of
	0 ->
	    io:format("sending interest !!!~n"),
	    put(am_interested,1),
	    gen_tcp:send(Socket,<<0,0,0,1,2>>);
	1 ->
	    io:format("already interested !!! ~n")
    end.


send_request([],_) -> 
    io:format("sending request finished~n");
send_request([H|T],Socket)->
    {I,_Blocks} = H,
    Request = <<0,0,0,13,6,I:32/integer-big,0:32/integer-big,32768:32/integer-big>>,
    io:format("sending request for piece index : ~w~n",[Request]),
    %%Index = <<I:32/binary>>,
    %%B = <<0:32>>,
    %%BS = <<32768:32>>,
    gen_tcp:send(Socket,Request),
    send_request(T,Socket).

    


%% messages_loop(Socket,Msg,Remain)->
%%     case Msg of 
%% 	[0,0,0,0] ->
%% 	    io:format("recieve Keepalive !!!"),
%% 	    gen_tcp:send(Socket,<<0,0,0,0>>),
%% 	    loop(Socket,Remain);
%% 	[0,0,0,1|Rest] ->
%% 	    case hd(Rest) of
%% 		0 ->
%% 		    choked;
%% 		1 ->
%% 		    io:format("recieve UNCHOKE !!!"),
%% 		    Size = 32768,
%% 		    Block = 0,
%% 		    {I,_}= hd(get()),
%% 		    io:format("bitfield it is finished ~n"),
%% 		    %%lists:map(fun(I,Size,Block,Socket) -> gen_tcp:send(Socket,<<0,0,0,13,6,I:32,Block:32,Size:32>>)end,get())
%% 		    %%%gen_tcp:send(Socket,<<0,0,0,1,2>>),
%% 		    gen_tcp:send(Socket,<<0,0,0,13,6,I:32,Block:32,Size:32>>),
%% 		    loop(Socket,Remain);
%% 		2 ->
%% 		    interested;
%% 		3 ->
%% 		    notinterested
%% 	    end;
%% 	[0,0,0,13|Rest] ->
%% 	    index13;
%% 	[0,0,0,5|Rest] ->
%% 	    index5;
%% 	[0,0,0,3]->
%% 	    index3;
%% 	[19,66,105,116|Rest] ->
%% 	    case length(Rest) of
%% 		64 ->
%% 		    io:format("first recieve 64 message ~n"),
%% 		    loop(Socket,Remain);
%% 		_ ->
%% 		    io:format("first recieve more than 64 message ~n"),
%% 		    New_Rest = lists:nthtail(64,Rest),
%% 		    <<Bitfield_length:32>> = list_to_binary(lists:sublist(New_Rest,4)),
%% 		    Bitfield = lists:nthtail(5,New_Rest),
%% 		    New_Remain = check_bitfield2(Bitfield,Bitfield_length-1,Socket),
%% 		    loop(Socket,New_Remain)
%% 	    end;
%% 	_ ->
%% 	    case Remain of 
%% 		0 ->
%% 		    io:format("we wish for recieve pieces ~n"),
%% 		    piece;
%% 		-1 ->
%% 		    <<Bitfield_length:32>> = list_to_binary(lists:sublist(Msg,4)),
%% 		    Bitfield = lists:nthtail(5,Msg),
%% 		    New_Remain = check_bitfield2(Bitfield,Bitfield_length-1,Socket),
%% 		    loop(Socket,New_Remain);
%% 		_ ->
%% 		    io:format("bitfield it is not finished ~n"),
%% 		    New_Remain = check_bitfield2(Msg,Remain,Socket), 
%% 		    loop(Socket,New_Remain)
%% 	    end			  
%%     end.


%% check_bitfield2(Msg,Remain,Socket)->
%%     case length(Msg) > Remain of
%% 	true ->
%% 	    Have_list = lists:nthtail(Remain,Msg),
%% 	    io:format("bitfield it is finished ~n"),
%% 	    io:format("send intersted ~n"),
%% 	    gen_tcp:send(Socket,<<0,0,0,1,2>>),
%% 	    io:format("after bitfield : ~w~n",[Have_list]),
%% 	    check_have(Have_list,Socket),
%% 	    0;
%% 	false ->
%% 	    Remain - length(Msg)
%%     end.
%% check_have([],_Socket)->
%%     io:format("have finished !!!!");
%% check_have([0,0,0,5|Rest],Socket) ->
%%     %io:format("cheking have !!!! ~n"),
%%     <<Piece_index:32>> = list_to_binary(lists:sublist(lists:nthtail(1,Rest),4)),
%%     %io:format("send request for ~w~n",[Piece_index]),
%%     put(Piece_index,[]),
%%     check_have(lists:nthtail(5,Rest),Socket);
%% check_have(Other,Socket) ->
%%     messages_loop(Socket,Other,0).
