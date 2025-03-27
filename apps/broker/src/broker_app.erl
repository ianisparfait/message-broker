-module(broker_app).
-behaviour(application).

-export([start/2, stop/1]).

start(_StartType, _StartArgs) ->
    % Démarrage du superviseur principal
    broker_sup:start_link().

stop(_State) ->
    ok.