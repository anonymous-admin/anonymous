%%Author:Massih
%%Creation Date: 11-Nov-2011
-module(peers_interactor).
-export([init/1,start_link/1]).
-export([test/0,handshake/1,test1/2]).
-behaviour(gen_server).
-include("defs.hrl").

init(Data)->
    handshake(Data),
    {ok,Data}.

terminate(_Reason,Data)->
    ok.

start_link(Data)->
    gen_server:start_link(?MODULE,Data,[]).

create_handshake_message(Ip,Port)->
    %%M = [19,"bittorrent protocol",<<0.0.0.0.0.0.0.0 /binary>>,"%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A","edocIT00855481937666"],
   %% M2 = lists:map(fun(X)->list_to_binary([X]) end,M).
    %%Message = .
ok.
    
handshake([Ip,Port])->
    Msg = list_to_binary([<<19>>,<<"BitTorrent protocol">>,
			  <<0,0,0,0,0,0,0,0>>,
			  "167126419EF184B4EC8FB3CA465AB7FED197519A",
			  "-AZ4004-znmphhbrij37"]),
    io:format("message = ~p~n ",[Msg]),
    Connection =  gen_tcp:connect(Ip,Port,[binary,{active,true}]),
    case Connection of
	{ok,Socket}->
	    X = gen_tcp:send(Socket,Msg),
	    io:format("result = ~p~n ",[X]);
	{error,Error} ->
	    gen_tcp:cast(logger,{peer_handshake_error,Error}),
	    undefined
	end,
 %   Socket = create_socket(Ip,Port),
 %   gen_tcp:send(,Msg),
    receive
	R->
	    R
end.


test()->
    URL = "http://torrent.fedoraproject.org:6969/announce?&info_hash=%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A&peer_id=-AZ4004-znmphhbrij37&port=6881&downloaded=10&left=1588&event=started&numwant=2",
    inets:start(),
    {ok,Result} = httpc:request(URL),
    {_Status_line, _Headers, Body} = Result,
    Decoded_Body = newparse:decode(list_to_binary(Body)),
    {[{_,S},{_,L},{_,Interval},{_,Peers}],_}=Decoded_Body,
    io:format("seeds:~p  leechers:~p  interval :~p\n",[S,L,Interval]),
    Peers.

    
create_socket(Ip,Port)->
    Connection =  gen_tcp:connect(Ip,Port,[binary,{packet,0}]),
    case Connection of
	{ok,Socket}->
	    Socket;
	{error,Error} ->
	    gen_tcp:cast(logger,{peer_handshake_error,Error}),
	    undefined
	end.
test1(Host,Port)->
    I = "%16%71%26%41%9E%F1%84%B4%EC%8F%B3%CA%46%5A%B7%FE%D1%97%51%9A",
    {ok, Socket} = gen_tcp:connect(Host, Port, [binary, {active, true}]), 
    gen_tcp:send(Socket, list_to_binary([
    19,                    % Protocol string length
    "BitTorrent protocol", % Protocol string
    <<0,0,0,0,0,0,0,0>>,   % Reseved space
    I,              % Info Hash
    "-AZ4004-znmphhbrij37" % Peer ID
  ])),
  receive
    {tcp,Socket,<<
        19,
        "BitTorrent protocol",
        _Reserved:8/binary,
        _InfoHash:20/binary,
        PeerID:20/binary
      >>} ->
      io:format("Received handshake from ~p~n", [PeerID]),
	  {ok, PeerID};
      _R ->
	  _R
  end.
