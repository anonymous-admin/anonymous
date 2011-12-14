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
                                                      {download_speed,-1}, {upload_speed,-1}, {filename,-1}]}),
    {ok, NodeAtom}.

terminate(_Reason, _NodeAtom) ->
    gen_server:cast(gui, stop).

handle_cast(stop, _NodeAtom) ->
    {stop, normal, _NodeAtom};

handle_cast({notify, _Tag, {-1, _Value}}, NodeAtom) ->
    {noreply, NodeAtom};

handle_cast({notify, Tag, {Id, Value}}, NodeAtom) ->
    TorrentId = Id,

    Target = {mailbox2, NodeAtom},
    
        %%receives from other erlang modules sends back to notice java
    case Tag of
    	torrent_info ->
	    Filename = Value#torrent.filename,
	    %Seeders = Value#torrent.seeders,
	    %Leechers = Value#torrent.leechers,
	    Size = Value#torrent.size,
	    Downloaded = Value#torrent.downloaded,
	    Files = Value#torrent.files,
	    %{mailbox2, NodeAtom} ! {self(), TorrentId, 5, Seeders},
	    %{mailbox2, NodeAtom} ! {self(), TorrentId, 6, Leechers},
	    Target ! {self(), TorrentId, 1, Size},
	    Target ! {self(), TorrentId, 7, Downloaded},
	    Target ! {self(), TorrentId, 0, Filename},
	    sendFiles(Files, NodeAtom, TorrentId);

	filename ->
	    Target ! {self(), TorrentId, 0, Value};

	tracker_info ->
	    Uploaded = Value#tracker_info.uploaded,
	    Target ! {self(), TorrentId, 8, Uploaded};

	file_path ->
	    Files = Value#torrent.files,
	    Target ! {self(), TorrentId, 13, Files};

	torrent_status ->
	    case Value of
		finished -> {mailbox2, NodeAtom} ! {self(), TorrentId, 14, Value};
	        _ -> ok
	    end;

	torrent_size ->
	    Target ! {self(), TorrentId, 1, Value};
	download_speed ->
	    Target ! {self(), TorrentId, 3, Value};
	upload_speed ->
	    Target ! {self(), TorrentId, 4, Value};
	seeders ->
	    io:format("gui got seeders: ~p~n", [Value]),
	    Target ! {self(), TorrentId, 5, Value};
	leechers ->
	    Target ! {self(), TorrentId, 6, Value};
	downloaded ->
	    Target ! {self(), TorrentId, 7, Value};
	uploaded ->
	    Target ! {self(), TorrentId, 8, Value};
	finished ->
	    Target ! {self(), TorrentId, 9, "Torrent finished downloading"}
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
	    gen_server:cast(msg_controller, {notify, torrent_status, {-1, opened}}),
	    gen_server:cast(msg_controller, {notify, torrent_filepath,{-1, FileDir}});
	{_From, Id, start} ->
	    io:format("Message received: ~p~n", [resumed]),
	    gen_server:cast(msg_controller, {notify, torrent_status,{Id, resume}});
	{_From, Id, stop} ->
	    io:format("Message received: ~p~n", [stopped]),
       	    gen_server:cast(msg_controller, {notify, torrent_status,{Id, stopped}});
	{_From, Id, pause} ->
	    io:format("Message received: ~p~n", [paused]),
	    gen_server:cast(msg_controller, {notify, torrent_status, {Id, paused}});
	{_From, Id, delete} ->
	    io:format("Message received: ~p for id: ~p~n", [deleted, Id]),
	    gen_server:cast(msg_controller, {notify, torrent_status, {Id, deleted}});
	{_From, dir,DirList} ->
	    io:format("Counter is at value: ~p~n", [DirList]),
	    gen_server:cast(msg_controller, {notify, default_path,{-1, DirList}})
    end,
    {noreply, NodeAtom}.

sendFiles([],_,_) ->
    ok;
sendFiles([H|T], NodeAtom, TorrentId) ->
    [[ToSend]|_] = H,
    {mailbox2, NodeAtom} ! {self(), TorrentId, 10, binary_to_list(ToSend)},
    sendFiles(T, NodeAtom, TorrentId).

code_change(_, _, _) ->
    ok.

handle_call(_, _, _) ->
    ok.
