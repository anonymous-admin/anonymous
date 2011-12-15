%%Author : Massih
%%Creation Date : 8-Nov-2011 
-module(peers_interactor).
-export([init/1,start_link/1,terminate/2,handle_cast/2,handle_call/3]).
-export([test/0,handshake/1]).
-behaviour(gen_server).
-include("defs.hrl").

init([Torrent, Ip, Port])->
    %gen_server:cast(Torrent#torrent.id, {peer_spawned, list_to_atom(Ip)}),
    gen_server:cast(msg_controller, {subscribe, list_to_atom(Ip), [{available_pieces, Torrent#torrent.id}, {get_blocks, Torrent#torrent.id},
								   {torrent_status, Torrent#torrent.id}]}),
    %handshake([Torrent, Ip, Port]),
    {ok,[Torrent, Ip, Port]}.

terminate(_Reason,Data)->
    ok.

start_link([Torrent, Ip, Port])->
    gen_server:start_link({local,list_to_atom(Ip)},?MODULE,[Torrent, Ip, Port],[]).

handle_call(Request,_From,Data) ->
    {reply,null,Data}.

handle_cast(stop, _Data) ->
    {stop, normal, _Data};

handle_cast({notify, torrent_status, {_Id, deleted}}, _Data) ->
    gen_server:cast(self(), stop),
    {noreply, _Data};

handle_cast(Request,Data)->
    {noreply,Data}.

handshake([Torrent, Ip, Port])->
    io:format("connecting to ip: ~p~n in port : ~p~n",[Ip,Port]),
    %%----------------------------------HARD CODED--------------------------
    Msg = list_to_binary([<<19>>,<<"BitTorrent protocol">>,
			  <<0,0,0,0,0,0,0,0>>,
			  atom_to_list(Torrent#torrent.id),
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
	    put(requested_piece,{-1,-1}),
	    put(downloaded_piece,[]),
	    put(torrent,Torrent),
	    PID = peer_message_handler:start(self()),
	    gen_tcp:send(Socket,Msg),
	    loop(Socket,-1,PID);
	%%receive {_,_,M}->io:format("handshake recieve -> ~w~n",[M])end,
						%receive_loop(Socket,0,0,0,0,[],-1);
	{error,Error} ->
	    io:format("Error in handshake !!! ~p~n",[Error]),
	    gen_server:cast(logger,{peer_handshake_error,Error})
    end.



test()->
    URL = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A&peer_id=-AZ4004-znmphhbrij37&port=6881&downloaded=10&left=1588&event=started&numwant=12&compact=1",
    inets:start(),
    {ok,Result} = httpc:request(URL),
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = parser:decode(list_to_binary(Body)),
    [Interval,Seeds,Leechers,Peers]=interpreter:get_tracker_response_info(Decoded_Body),
    [IP,PORT] = hd(Peers).
    %%io:format("connecting to ip: ~p~n ",[hd(Peers)]),
    %%lists:map(spawn(fun(P)->handshake(P)end),Peers).
    %%handshake([binary_to_list(IP),PORT,_PID]).



loop(Socket,Remain,PID)->
    receive 
	{tcp,_,Msg} ->
	    %io:format("message is ~p~n",[Msg]),
	    PID ! Msg ,
	    loop(Socket,Remain,PID);
	    %%messages_loop(Socket,Msg,Remain);
	{tcp_closed,_R} ->
	    io:format("CLOSED !!!!!!!! ~w~n",[_R]),
	    gen_server:cast(logger,{peer_connection_closed}),
	    loop(Socket,Remain,PID);
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
	    send_request(get(peer_have_list),Socket),
	    %%io:format("pieces are ~w~n",[dict:to_list(get(peer_have_list))]),
	    loop(Socket,Remain,PID);
	get_choke ->
	    io:format("get choke !!!~n"),
	    put(am_choking,1),
	    loop(Socket,Remain,PID);
	get_keep_alive ->
	    io:format("get keep alive !!! ~n"),
	    gen_tcp:send(Socket,<<0,0,0,0>>),
	    loop(Socket,Remain,PID);
	{peer_have_piece,Piece_index} ->
	    Dict = get(peer_have_list),
	    Dict2 = dict:append(Piece_index,create_blocks_list(dict:new(),262144) ,Dict),
	    put(peer_have_list,Dict2),
	    loop(Socket,Remain,PID);
	{recieved_piece,Index,Begin,Block} ->
	    io:format("*************Piece recieved index is :~p     begin is : ~p~n block length is :~p~n",[Index,Begin,byte_size(Block)]),
	    %% save blocks to send them when a piece downloaded completely
	    %%%%%New_Blocks
	    New_blocks = get(downloaded_piece) ++ [[Index,Begin,Block]],
	    put(downloaded_piece,New_blocks),
	    send_request(get(peer_have_list),Socket),
	    %%Block_list = dict:fetch(Index,get(peer_have_list)),
	    %%gen_server:cast(msg_controller,{notify,set_block,{Tid,[Pid,Index,Begin,Block]}})
	    
	    %%TEST
	   %% file_handler ! {set_block,Index,Begin,list_to_binary(Block)},
	    %%gen_server:cast(intermediate,{notify,set_block,[Index,Begin,list_to_binary(Block)] }),
	    %%
	    
	    loop(Socket,Remain,PID);
	_Other ->
	    io:format("receive unknown message from a peer !!! ~n~w~n",[length(_Other)]),
	    loop(Socket,Remain,PID)
    after 60000 ->
	    PID ! stop,
	    %io:format("time out  !!!~n and all dic info is ~w~n",[erase()]),
	    gen_tcp:close(Socket)
    end.

create_blocks_list(Dict,0) ->
    dict:store(0,0,Dict);
create_blocks_list(Dict,Num) ->
    create_blocks_list(dict:store(Num-32768,0,Dict),Num-32768).



send_interest(Socket)->
    case get(am_interested) of
	0 ->
	    io:format("sending interest !!!~n"),
	    put(am_interested,1),
	    gen_tcp:send(Socket,<<0,0,0,1,2>>);
	1 ->
	    io:format("already interested !!! ~n")
    end.

%%send_request([],_) -> 
%%    io:format("nothing to send request~n");
send_request(Dict,Socket)->
    All_pieces = dict:fetch_keys(Dict),
    if 
	length(All_pieces) > 0 ->
	    case get(requested_piece) of
		{-1,-1} ->
		    I = hd(All_pieces),
		    %%DONT FORGET TO CHECK FOR LAST PIECE*********************************
		    %% HERE
		    Block = 0,
		    Request = <<0,0,0,13,6,I:32/integer-big,Block:32/integer-big,32768:32/integer-big>>,
		    io:format("sending request for piece index : ~w~n",[Request]),
		    put(requested_piece,{I,Block}),
		    %%New_dict = dict:store(I,[0],Dict),
		    %%put(peer_have_list,New_dict),
		    gen_tcp:send(Socket,Request);
		{I,B} ->
		    %%B = lists:last(dict:fetch(I,Dict)),
		    %%----------------------------HARD CODED-----------------------(Block size,Piece size)
		    Next_block = B + 32768,
		    Request = <<0,0,0,13,6,I:32/integer-big,Next_block:32/integer-big,32768:32/integer-big>>,
		    gen_tcp:send(Socket,Request),
		    if 
			Next_block == 262144 ->  %%262144 is piece_length
			    put(requested_piece,{-1,-1}),
			    New_dict = dict:erase(I,Dict),
			    io:format("send all blocks of a piece together : ~p~n",[length(get(downloaded_piece))]),
			    gen_server:cast(intermediate,{notify,set_block,{1,get(downloaded_piece)} }),
			    put(downloaded_piece,[]),
			    put(peer_have_list,New_dict);
			true ->
			    put(requested_piece,{I,Next_block}) 
			    %%New_dict = dict:store(I,B++[Next_block],Dict),
			    %%put(peer_have_list,New_dict)
		    end
	    end;
	true ->
	    io:format("Unchoke but Havent recieve any piece index !!!!")
    end.


    %%Index = <<I:32/binary>>,
    %%B = <<0:32>>,
    %%BS = <<32768:32>>,
 
    %%send_request(T,Socket).
