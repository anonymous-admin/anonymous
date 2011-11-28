-module(talkToJava).
-export([start/0]).

start() ->
    ComputerName = net_adm:localhost(),
    NodeName = "javaNode@" ++ ComputerName,
    NodeAtom = list_to_atom(NodeName),
    timer:sleep(2000),
    {mailbox, NodeAtom} ! {self(), "startconnection"},
    rec(NodeAtom).

rec(NodeAtom) ->

    receive

        %%receives from java
	{_From, connok} ->
	    io:format("Message received: ~p~n", [connectionok]);   

	{_From, open,FileList} ->
	    io:format("Message received: ~p~n", [FileList]);
	%%torrentInterpreter ! {self(), open, FileList},
	{_From, start} ->
	    io:format("Message received: ~p~n", [started]);
	%%interactorcomponent ! {self() start},
	{_From, stop} ->
	    io:format("Message received: ~p~n", [stopped]);
	%%interactorcomponent ! {self(), stop},
	{_From, delete} ->
	    io:format("Message received: ~p~n", [deleted]);
	%%process ! {self(), delete},
	{_From, dir,DirList} ->
	    io:format("Counter is at value: ~p~n", [DirList]);
	%%process ! {self(), directory,DirList},

       	%%receives from other erlang modules sends back to notice java
	

	{TorrentId, status, Value} ->
	    case Value of
	    started -> {mailbox2, NodeAtom} ! {self(), TorrentId, 10, Value};
	    stopped -> {mailbox2, NodeAtom} ! {self(), TorrentId, 11, Value};
	    deleted -> {mailbox2, NodeAtom} ! {self(), TorrentId, 12, Value};
	    paused ->  {mailbox2, NodeAtom} ! {self(), TorrentId, 13, Value};
	    finished -> {mailbox2, NodeAtom} ! {self(), TorrentId, 14, Value}
	      
		end;

	{TorrentId, filename, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 0, Value};
	{TorrentId, filesize, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 1, Value};
	{TorrentId, tracker, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 2, Value};
	{TorrentId, downspeed, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 3, Value};
	{TorrentId, upspeed, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 4, Value};
	{TorrentId, seeders, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 5, Value};
	{TorrentId, leechers, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 6, Value};
	{TorrentId, downloaded, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 7, Value};
	{TorrentId, uploaded, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 8, Value};
	{TorrentId, files, Value} ->
	    {mailbox2, NodeAtom} ! {self(), TorrentId, 9, Value}
    end,
    rec(NodeAtom).

