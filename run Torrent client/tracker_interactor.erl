%%Author: Massih
%%Creation Date: 2-Nov-2011
-module(tracker_interactor).
-export([init/1,start_link/1,handle_cast/2,terminate/2]).
-export([handle_call/3, handle_info/2, code_change/3]).
-export([create_record/0, make_url/1, send_request/1, response_handler/1]).
-behaviour(gen_server).
-include("defs.hrl").


init([Tracker, Timeout, Torrent])->
    URL = make_url(Tracker#tracker_info{event="started"}),
    io:format("Tracker started: ~p~n", [URL]),
    {Data, NewTimeout} = case send_request(URL) of
	{ok,Result} ->
	    io:format("in case~n"),
	    [Seeders,Leechers,Interval,Peers] = response_handler(Result),
	    NewTracker = Tracker#tracker_info{interval=integer_to_list(Interval),event=""},
	    gen_server:cast(msg_controller, {notify, seeders, {Torrent#torrent.id, integer_to_list(Seeders)}}),
	    {{NewTracker, Torrent},Interval};
	{error,_Reason} ->
	    io:format("Request error"),
	    %%gen_server:cast(msg_controller,{tracker_request_error,Reason})
	    terminate([], []),
	    {{Tracker, Torrent},Timeout};
	Last -> io:format("Bad clause: ~p~n", [Last])	
    end,
    io:format("tracker init done"),
    {ok, Data, NewTimeout}.

terminate(_Reason,_Data)->
    gen_server:cast(self(), stop).

start_link([Tracker, Timeout, Torrent])->
    gen_server:start_link(?MODULE,[Tracker, Timeout, Torrent],[]).

send_request(URL)->
    inets:start(),
    httpc:request(URL).

make_url(T)->
    io:format("Creating URL: ~p~n", [T]),
    T#tracker_info.url++"?info_hash="++T#tracker_info.info_hash++"&peer_id="++T#tracker_info.peer_id++"&port="++T#tracker_info.port++"&downloaded="++T#tracker_info.downloaded++"&left="++T#tracker_info.left++"&event="++T#tracker_info.event++"&numwant="++T#tracker_info.num_want++"&uploaded="++T#tracker_info.uploaded++"&compact=1".


response_handler(Result)->
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = parser:decode(list_to_binary(Body)),
    [Interval,Seeds,Leechers,Peers]=interpreter:get_tracker_response_info(Decoded_Body),
    io:format("after response info~n"),
    %%io:format("seeds:~p  leechers:~p  interval :~p\n",[S,L,NewInterval]),
    [Seeds,Leechers,Interval,Peers].

handle_cast(stop, _Data)->
    {stop, normal, _Data};

handle_cast(tracker_request_info,{Tracker, Torrent})->
    URL = make_url(Tracker),
    io:format("The url is ~p~n", [URL]),
    {Data, Timeout} = case send_request(URL) of
	{ok,Result} ->
	    [Seeders,Leechers,Interval,Peers] = response_handler(Result),
	    spawn_peers(Peers, Torrent),
	    NewTracker = Tracker#tracker_info{interval=integer_to_list(Interval)},
	    %SEND BACK INFO TO TORRENT
	    gen_server:cast(msg_controller, {notify, seeders, {Torrent#torrent.id, integer_to_list(Seeders)}}),
	    {{NewTracker,Torrent},Interval};
	{error,_Reason} ->
	    %%gen_server:cast(msg_controller,{tracker_request_error,Reason})
	    io:format("Request Error"),
	    gen_server:cast(self(), stop),
	    {{Tracker,Torrent},list_to_integer(Tracker#tracker_info.interval)}
    end,
    {noreply, Data, Timeout}.

handle_info(timeout, {Tracker, Torrent}) ->
    io:format("Interval"),
    case whereis(Torrent#torrent.id) of
	undefined -> 
	    NewTracker = Tracker,
	    {error, dead};
        _         ->
            {Downloaded, Left, Event, Max_peers} = gen_server:call(Torrent#torrent.id, get_dynamics),
            NewTracker = Tracker#tracker_info{downloaded=Downloaded, left=Left, event=Event, num_want=Max_peers},
            gen_server:cast(self(), tracker_request_info)
    end,
    {noreply, {NewTracker,Torrent},NewTracker#tracker_info.interval}.
    

create_record() ->
    T = #tracker_info{url = "http://torrent.fedoraproject.org:6969/announce",
		      info_hash = "%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A",
		      peer_id = "edocIT00855481937666",
		      port = "6881"},
    T.

spawn_peers([], _) ->
    ok;
spawn_peers([H|T], Torrent) ->
    [Ip,Port] = H,
    case whereis(list_to_atom(Ip)) of
	undefined -> dynamic_supervisor:start_peer(Torrent, Ip, Port);
	_         -> ok
    end,
    spawn_peers(T, Torrent).

handle_call(_,_,_) ->
    ok.

code_change(_,_,_) ->
    ok.
    

