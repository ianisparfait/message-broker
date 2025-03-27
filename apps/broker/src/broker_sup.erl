-module(broker_sup).
-behaviour(supervisor).

-export([start_link/0, init/1]).

start_link() ->
    supervisor:start_link({local, ?MODULE}, ?MODULE, []).

init([]) ->
    SupFlags = #{
        strategy => one_for_one,
        intensity => 10,
        period => 60
    },

    % Définition des workers/processus à superviser
    ChildSpecs = [
        #{
            id => broker_queue,
            start => {broker_queue, start_link, []},
            restart => permanent,
            shutdown => 5000,
            type => worker,
            modules => [broker_queue]
        }
    ],

    {ok, {SupFlags, ChildSpecs}}.