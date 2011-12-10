-module(talkToJava).
-export([start_link/0, start_link/1, stop/0]).
-export([init/1, terminate/2, handle_cast/2, 
	 handle_info/2, code_change/3, handle_call/3]).
-behaviour(gen_server).

-include("defs.hrl").

start_link() ->
    start_link([]).

start_link(_Args) ->
    ComputerName = net_adm:localhost(),
    NodeName = "javaNode@" ++ ComputerName,
    NodeAtom = list_to_atom(NodeName),
    gen_server:start_link({local, gui}, ?MODULE, NodeAtom, []).

stop() ->
    gen_server:cast(gui, stop).

init(NodeAtom) ->
    timer:sleep(4000),
    {mailbox, NodeAtom} ! {self(), "startconnection"},
    gen_server:cast(msg_controller, {subscribe, gui, [{exit,-1}, {torrent_info,-1}, {torrent_status,-1}, 
                                                      {tracker_info,-1}, {seeders,-1}, {leechers,-1}, 
                                                      {uploaded,-1}, {downloaded,-1}, {left,-1},
						      {torrent_size,-1}, {pieces,-1},
                                                      {download_speed,-1}, {upload_speed,-1}]}),
    {ok, NodeAtom}.

terminate(_Reason, _NodeAtom) ->
    gen_server:cast(gui, stop).

handle_cast(stop, _NodeAtom) ->
    {stop, normal, _NodeAtom};

handle_cast(Request, NodeAtom) ->
    
        %%receives from other erlang modules sends back to notice java
    case Request of
    	{notify, torrent_info, {TorrentId, Value}} ->
	    %Seeders = integer_to_list(Value#torrent.seeders),
	    %Leechers = integer_to_list(Value#torrent.leechers),
	    Size = integer_to_list(Value#torrent.size),
	    Downloaded = integer_to_list(Value#torrent.downloaded),
	    Files = Value#torrent.files,
	    %{mailbox2, NodeAtom} ! {self(), TorrentId, 5, Seeders},
	    %{mailbox2, NodeAtom} ! {self(), TorrentId, 6, Leechers},
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 1, Size},
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 7, Downloaded},
	    sendFiles(Files, NodeAtom, TorrentId);

	{notify, tracker_info, {TorrentId, Value}} ->
	    Uploaded = integer_to_list(Value#tracker_info.uploaded),
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 8, Uploaded};

	{notify, file_path, {TorrentId, Value}} ->
	    Files = integer_to_list(Value#torrent.files),
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 13, Files};

	{notify, torrent_status, {TorrentId, Value}} ->
	    case Value of
		finished -> {mailbox2, NodeAtom} ! {self(), TorrentId, 14, Value};
	        _ -> ok
	    end;

	{notify, torrent_size, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 1, Value};
	{notify, download_speed, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 3, Value};
	{notify, upload_speed, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 4, Value};
	{notify, seeders, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 5, Value};
	{notify, leechers, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 6, Value};
	{notify, downloaded, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 7, Value};
	{notify, uploaded, {TorrentId, Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 8, Value};
	{notify, finished, {TorrentId, _Value}} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 9, "Torrent finished downloading"}
    end,
    {noreply, NodeAtom}.

handle_info(Info, NodeAtom) ->
    case Info of
        %%receives from java
	{_From, connok} ->
	    io:format("Message received: ~p~n", [connectionok]);   
	{_Fron, exit} ->
	    io:format("Message received: ~p~n", [exited]),
	    gen_server:cast(msg_controller, {notify, exit, exit});
	{_From, open,FileDir} ->
	    io:format("Message received: ~p~n", [FileDir]),
	    gen_server:cast(msg_controller, {notify, torrent_status, {torrent1, opened}}),
	    gen_server:cast(msg_controller, {notify, torrent_filepath,{torrent1, FileDir}});
	{_From, start} ->
	    io:format("Message received: ~p~n", [resumed]),
	    gen_server:cast(msg_controller, {notify, torrent_status,{torrent1, resume}});
	{_From, stop} ->
	    io:format("Message received: ~p~n", [stopped]),
       	    gen_server:cast(msg_controller, {notify, torrent_status,{torrent1, stopped}});
	{_From, pause} ->
	    io:format("Message received: ~p~n", [paused]),
	    gen_server:cast(msg_controller, {notify, torrent_status, {torrent1, paused}});
	{_From, delete} ->
	    io:format("Message received: ~p~n", [deleted]),
	    gen_server:cast(msg_controller, {notify, torrent_status,{torrent1, deleted}});
	{_From, dir,DirList} ->
	    io:format("Counter is at value: ~p~n", [DirList]),
	    gen_server:cast(msg_controller, {notify, default_path,{torrent1, DirList}})
    end,
    {noreply, NodeAtom}.

sendFiles([],_,_) ->
    ok;
sendFiles([H|T], NodeAtom, TorrentId) ->
    {mailbox2, NodeAtom} ! {self(), TorrentId, 10, H},
    sendFiles(T, NodeAtom, TorrentId).

code_change(_, _, _) ->
    ok.

handle_call(_, _, _) ->
    ok.
