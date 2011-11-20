%%Author: Johan and Massih

-module(torrent).
-export([init/1,start_link/1,handle_call/3,handle_cast/2,terminate/2]).
-behaviour(gen_server).
-include("defs.hrl").

init(Torrent_info) ->
    Dict = dict:new(),
    {NewDict, Entries} = spawn_trackers(Torrent_info#torrent.trackers, Dict, 1),
    {ok, {NewDict, Entries}}.

terminate(_Reason, {Dict, Entries}) ->
    ok.

start_link(Trackers) ->
    gen_server:start_link(?MODULE,Trackers,[]).

handle_cast(_Operation, {Dict, Entries}) ->
    ok.

handle_call({_Operation, _Item}, _From, {Dict, Entries}) ->
    Reply = ok,
    {reply, Reply, {Dict, Entries}}.

spawn_trackers([], Dict, Entries) ->
    {Dict, Entries};
spawn_trackers([H|T], Dict, Entries) -> 
    {_, Pid} = tracker_supevisor:start_tracker([H]),
    Result = gen_server:call(Pid, info_to_send(H,"started")),
    [_Seeders,_Leechers,Interval,_Peers] = Result,
    gen_server:cast(logger, Result),
    spawn_link(fun() -> interval_loop(H, Pid) end),
    NewDict = dict:store(Entries, Pid, Dict),
    spawn_trackers(T, NewDict, Entries+1).

interval_loop(Tracker, Pid) ->
    receive
    after Tracker#tracker_info.interval ->
	    gen_server:call(Pid, info_to_send(Tracker,""))
    end,
    interval_loop(Tracker, Pid).

info_to_send(Tracker, Event) ->
    {tracker_request_info, 
     {Tracker#torrent.downloaded, 
     (Tracker#torrent.size-Tracker#torrent.downloaded),
     Event, Tracker#torrent.max_peers}}.
