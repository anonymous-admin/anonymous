%%date:301011.

%%author(Aida-Monzavi).
-module(newparse).
-export([parse/1,decode/1]).

%-----------------------------------------------------------------------
% Test stuff, to be removed when functions are verified
-export([log/1]).

log(Data) ->
    file:write_file("parsedtorrent.txt",io_lib:fwrite("~p.\n",[Data])).
%-----------------------------------------------------------------------

parse(F)->
     {ok,Info}=file:read_file(F),
     decode(Info).
    
 
decode(Info)->
    case Info of
    <<$i,Tail/binary>>->
	    decode_int(Tail);
    <<$l,Tail/binary>>->
            decode_list(Tail);
    <<$d,Tail/binary>>->
            decode_dictionary(Tail,[]);
    
	_String->
	    decode_string(_String)
end.

decode_int(<<H,Tail/binary>>)->
    decode_int(<<H,Tail/binary>>,[]).
decode_int(<<"e",Tail/binary>>,Int)->
    {lists:reverse(Int),Tail};
decode_int(<<H,Tail/binary>>,Int) ->
    decode_int(Tail,[H|Int]).

decode_string(String)->
    decode_string(String,[]).
decode_string(<<$:,Tail/binary>>,L)->
    Length = list_to_integer(lists:reverse(L)),
    <<String:Length/binary,R/binary>> = Tail,
    {String,R};    
decode_string(<<Number,Tail/binary>>,Length)->
         decode_string(Tail,[Number|Length]).

decode_list(<<H,Tail/binary>>)->
    decode_list(<<H,Tail/binary>>,[]).
decode_list(<<"e",Tail/binary>>,List)->
    {lists:reverse(List),Tail};
decode_list(_list,List) ->
    {Element,Tail} = decode(_list),
    decode_list(Tail,[Element|List]).

decode_dictionary(<<"e",Tail/binary>>,Dic)->
          {lists:reverse(Dic),Tail};
decode_dictionary(Dict,Dic) ->
        {Key,Tail}=decode(Dict),
        {Value,Newtail}=decode(Tail),
        L={Key,Value},
          decode_dictionary(Newtail,[L|Dic]).
