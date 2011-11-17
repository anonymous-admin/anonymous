%%Author: Massih
%%Creation Date: 2-Nov-2011
-module(tracker_interactor).
-export([send_request/1,make_url/0,get_info/0,test/0]).
-record(tracker_info,{torrent_id,info_hash,peer_id,port,uploaded,downloaded,left,event,maxnum,interval=20000}).


tracker_interactor_start(T_id,Info_hash,Peer_id,Port,Uploaded,Downloaded,Left,Event,Maxnum)->
    register(?MODULE,spawn(fun()->request_tracker_loop(20000)end)).


send_request(URL)->
    inets:start(),
    httpc:request(URL).


test()->
   URL = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%EA%9CR%23%29z%29%7D%02%E352t%8B%96ED%3C%99%23&peer_id=edocIT00855481937666&port=6881&downloaded=10&left=1588&event=started",
    inets:start(),
    httpc:request(URL).


make_url()->
    URL = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A&peer_id=edocIT00855481937666&port=6881&downloaded=10&left=1588&event=started".    

    %%send_request(URL).
response_handler({ok,Result})->
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = newparse:decode(list_to_binary(Body)),
    {[{_,S},{_,L},{_,NewInterval},{_,Peers}],_}=Decoded_Body,
    io:format("seeds:~p  leechers:~p  interval :~p\n",[S,L,Interval]),
    ok;
response_handler({error,Reason}) ->
    Reason.
    

request_tracker_loop(Interval) ->
    receive
	{torrent_status,From,Event}->
	    URL = make_url(started),
	    URL1 = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%96%3B%40%D8%0At%0AG%AE6%A6%C9%E8%C1%40%B0%90N%26%FE&peer_id=edocIT00855481937666&port=6881&downloaded=10&left=1588&event=started",		 
	    case send_request(URL) of
		{ok,Result} ->
		     = Result,
		    %%Peers;
		    request_tracker_loop(NewInterval);
		{error,Reason} ->
		    Reason
	    end;
	{pause,From}->
	    stop;
	{complete,From} ->
end.






%%    {ok, Socket} = gen_tcp:connect("torrent.fedoraproject.org",6969, [binary, {%%active, true}]),
%%    gen_tcp:send(Socket, list_to_binary([
%%    19,                    % Protocol string length
%%    "BitTorrent protocol", % Protocol string
%%    <<0,0,0,0,0,0,0,0>>,   % Reseved space
%%    "167126419ef184b4ec8fb3ca465ab7fed197519a",% Info Hash
%%    "-AZ4004-znmphhbrij37" % Peer ID
%%  ])),
%%  receive
%%    {tcp,Socket,<<
%%        19,
%%        "BitTorrent protocol",
%%        _Reserved:8/binary,
%%        _InfoHash:20/binary,
%%        PeerID:20/binary
%%      >>} ->
%%      io:format("Received handshake from ~p~n", [PeerID]),
%%	  {ok, PeerID};
%%      _dont ->
%%	  buggs
%%  end.

get_info()->
    ok.
    %%Info_hash= edoc_lib:escape_uri("167126419ef184b4ec8fb3ca465ab7fed197519a"),
    %%URL1 = "http://torrent.fedoraproject.org:6969/announce"++"?info_hash="++Inf%%o_hash++"&peer_id=" ++ "12345678912345678911" ++ "&port=" ++ "12345" ++ "&uploa%%ded=0&downloaded=0&left=" ++ integer_to_list(6504030) ++ "&compact=1&event=star%%ted",
%%    io:format("~p\n",[URL1]),



receive_data(Socket, SoFar) ->
    receive
	{tcp,Socket,Bin} ->
	    receive_data(Socket, [Bin|SoFar]);
	{tcp_closed,Socket} ->
	    list_to_binary(lists:reverse(SoFar))
    end.

