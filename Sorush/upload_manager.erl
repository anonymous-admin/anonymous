%%--------------------------------------------------------------------
%% @author Sorush Arefipour
%% @doc    upload_manager.erl
%% @spec   the module is listening to to a port and recieve message and
%%         responses to them accordingly
%% @end
%%--------------------------------------------------------------------
-module(upload_manager).
-compile(export_all).


%%--------------------------------------------------------------------
%% @doc    upload_manager.erl
%% @spec   it starts the module by listening to  port 6881 after 
%%         connecting a peer it accepts it and refer it to listener loop
%%         with the PeerSocket and the infohash.
%% @end
%%--------------------------------------------------------------------
start() ->
    {ok, ListenSocket} = gen_tcp:listen(6881, [binary, {packet, 0}, {active, false}]),
    io:format("Listen Socket is -> ~w~n",[ListenSocket]),
    TorrentID = <<22,113,38,65,158,241,132,180,236,143,179,202,70,90,183,254,209,151,81,154>>,
    {ok, PeerSocket} = gen_tcp:accept(ListenSocket),
    io:format("Peer Socket is -> ~w~n",[PeerSocket]),
    listener(TorrentID, PeerSocket).

%%--------------------------------------------------------------------
%% @doc    upload_manager.erl
%% @spec   it is the listening loop that recieve the message, first it
%%         checks for the handshake and answer properly and then wait
%%         for other messages
%% @end
%%--------------------------------------------------------------------
listener(TorrentID, PeerSocket) ->
    io:format("Listening to to the port 6881 ~n"),
    Incomming_msg = gen_tcp:recv(PeerSocket, 0),
    io:format("Incomming message is -> ~p~n",[Incomming_msg]),
    case Incomming_msg of
	{ok, << 19, "BitTorrent protocol", Rest/binary >>} ->
	    io:format("Message is -> ~p~n",[Rest]),
	    ListRest = binary_to_list(Rest),
	    InfoHash = list_to_binary(lists:sublist(ListRest,9,20)),
	    PeerID = lists:nthtail(29,ListRest),
	    io:format("InfoHash is -> ~p~n",[InfoHash]),
	    io:format("PeerID is -> ~p~n",[PeerID]),	    
	    case InfoHash == TorrentID of
		true ->	    
		    io:format("HandShake Accepted ~n"),
		    gen_tcp:send(PeerSocket, list_to_binary([19, "BitTorrent protocol", <<0,0,0,0,0,0,0,0>>,
							     TorrentID,list_to_binary("-AZ4004-znmphhbrij37"),<<0,0,6,206,5>>,get_bitfield(),<<0,0,0,5,4,0,0,12,23,0,0,0,5,4,0,0,64,21>>])),
		    put(handshake, true),
		    listener(TorrentID, PeerSocket);
		false ->
		    io:format("HandShake not accepted ~n"),
		    listener(TorrentID, PeerSocket)
	    end;
	{ok, Message} ->
	    case get(handshake) of
		true ->
		    msg_handler(Message, PeerSocket),
		    listener(TorrentID, PeerSocket);
		_ ->
		  listener(TorrentID, PeerSocket)
	    end
%	_Error ->
%	    io:format("HandShake not accepted ~n"),
%	    listener(TorrentID, ListenSocket)
    end.

%%--------------------------------------------------------------------
%% @doc    upload_manager.erl
%% @spec   Converts the number to big endian
%% @end
%%--------------------------------------------------------------------
big_endian(Binary) ->
    <<Number:32>> = Binary,
    Number.
%%--------------------------------------------------------------------
%% @doc    upload_manager.erl
%% @spec   Convert the number to little indian
%% @end
%%--------------------------------------------------------------------
little_endian(Number) ->
    <<Number:32>>.

%%--------------------------------------------------------------------
%% @doc    upload_manager.erl
%% @spec   It gets a list as argument and create a have list
%% @end
%%--------------------------------------------------------------------
create_have_message([])->
    list_to_binary([]);
create_have_message([H|T])->
    list_to_binary([little_endian(H)] ++ create_have_message(T)).


%%--------------------------------------------------------------------
%% @doc    upload_manager.erl
%% @spec   It gets binary and PeerSocket as argument and response to
%%         connected peer relatively
%% @end
%%--------------------------------------------------------------------
msg_handler(<<>>, PeerSocket) ->
    done;
msg_handler(<<0,0,0,0>>, PeerSocket) ->
    io:format("Keep Alive~n"),
    gen_tcp:send(PeerSocket, list_to_binary([0,0,0,0]));
msg_handler(<<0,0,0,1,0>>, PeerSocket) ->
    io:format("Choke~n");
msg_handler(<<0,0,0,1,1>>, PeerSocket) -> 
    io:format("Unchoke~n");
msg_handler(<<0,0,0,1,2>>, PeerSocket) -> 
    io:format("Interested~n"),
    gen_tcp:send(PeerSocket, list_to_binary([0,0,0,1,1]));
msg_handler(<<0,0,0,1,3>>, PeerSocket) ->
    io:format("Not Interested~n");
msg_handler(<<0,0,0,13,6,Remain/binary>>, PeerSocket) -> 
    io:format("Request is recieved ~n"),
    Index = big_endian(list_to_binary(lists:sublist(binary_to_list(Remain),4))),
    Begin = big_endian(list_to_binary(lists:sublist(binary_to_list(Remain),5,4))),
    Length = big_endian(list_to_binary(lists:nthtail(8,binary_to_list(Remain)))),
    io:format("Index -> ~w~nBegin -> ~w~nLength -> ~w~n", [Index,Begin,Length]),
    gen_tcp:send(PeerSocket, list_to_binary([[little_endian(Length)],7,[little_endian(Index)],[little_endian(Begin)],[123,123,124,124]]));
msg_handler(Other, PeerSocket) ->
    io:format("Other message:~w~n", [Other]).
