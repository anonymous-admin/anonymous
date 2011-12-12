%%Author: Massih
%%Creation Date: 2-Nov-2011
-module(tracker_interactor).
-export([init/1,start_link/1,handle_cast/2,terminate/2]).
-export([handle_call/3, handle_info/2, code_change/3]).
-export([create_record/0, make_url/1, send_request/1, response_handler/1]).
-behaviour(gen_server).
-include("defs.hrl").


init([Tracker, Timeout, TorrentId])->
    URL = make_url(Tracker#tracker_info{event="started"}),
    io:format("Tracker started: ~p~n", [URL]),
    {Data, NewTimeout} = case send_request(URL) of
	{ok,Result} ->
	    [Seeders,Leechers,Interval,Peers] = response_handler(Result),
	    NewTracker = Tracker#tracker_info{interval=integer_to_list(Interval),event=""},
	    %%SEND BACK INFO TO TORRENT
	    io:format("FIRST Seeders: ~p~n Leechers: ~p~n Interval: ~p~n Peers: ~p~n",
		      [Seeders, Leechers, Interval, Peers]),
	    {{NewTracker, TorrentId},Interval};
	{error,_Reason} ->
	    io:format("Request error"),
	    %%gen_server:cast(msg_controller,{tracker_request_error,Reason})
	    terminate([], []),
	    {{Tracker, TorrentId},Timeout}
    end,
    {ok, Data, NewTimeout}.

terminate(_Reason,_Tracker)->
    gen_server:cast(self(), stop).

start_link([Tracker, Timeout, TorrentId])->
    gen_server:start_link(?MODULE,[Tracker, Timeout, TorrentId],[{debug, [trace]}]).

send_request(URL)->
    inets:start(),
    httpc:request(URL).

make_url(T)->
    io:format("Creating URL: ~p~n", [T]),
    T#tracker_info.url++"?info_hash="++T#tracker_info.info_hash++"&peer_id="++T#tracker_info.peer_id++"&port="++T#tracker_info.port++"&downloaded="++T#tracker_info.downloaded++"&left="++T#tracker_info.left++"&event="++T#tracker_info.event++"&numwant="++T#tracker_info.num_want++"&uploaded="++T#tracker_info.uploaded.


response_handler(Result)->
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = parser:decode(list_to_binary(Body)),
    [Interval,Seeds,Leechers,Peers]=interpreter:get_tracker_response_info(Decoded_Body),
    %%io:format("seeds:~p  leechers:~p  interval :~p\n",[S,L,NewInterval]),
    [Seeds,Leechers,Interval,Peers].

handle_cast(stop, _Data)->
    {stop, normal, _Data};

handle_cast(tracker_request_info,{Tracker, TorrentId})->
    URL = make_url(Tracker),
    io:format("The url is ~p~n", [URL]),
    {Data, Timeout} = case send_request(URL) of
	{ok,Result} ->
	    [Seeders,Leechers,Interval,Peers] = response_handler(Result),
	    NewTracker = Tracker#tracker_info{interval=integer_to_list(Interval)},
	    io:format("Seeders: ~p~n Leechers: ~p~n Interval: ~p~n Peers: ~p~n",
		      [Seeders, Leechers, Interval, Peers]),
	    %SEND BACK INFO TO TORRENT
	    {{NewTracker,TorrentId},Interval};
	{error,_Reason} ->
	    %%gen_server:cast(msg_controller,{tracker_request_error,Reason})
	    io:format("Request Error"),
	    gen_server:cast(self(), stop),
	    {{Tracker,TorrentId},list_to_integer(Tracker#tracker_info.interval)}
    end,
    {noreply, Data, Timeout}.

handle_info(timeout, {Tracker, TorrentId}) ->
    io:format("Interval"),
    {Downloaded, Left, Event, Max_peers} = gen_server:call(TorrentId, get_dynamics),
    NewTracker = Tracker#tracker_info{downloaded=Downloaded, left=Left, event=Event, num_want=Max_peers},
    gen_server:cast(self(), tracker_request_info),
    {noreply, {NewTracker,TorrentId},NewTracker#tracker_info.interval}.
    

create_record() ->
    T = #tracker_info{url = "http://torrent.fedoraproject.org:6969/announce",
		      info_hash = "%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A",
		      peer_id = "edocIT00855481937666",
		      port = "6881"},
    T.

handle_call(_,_,_) ->
    ok.

code_change(_,_,_) ->
    ok.
    

