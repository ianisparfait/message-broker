-module(broker_queue).
-behaviour(gen_server).

-export([start_link/0, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([enqueue/2, dequeue/1, list_queues/0]).

% État du serveur
-record(state, {
    queues = #{}
}).

start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

enqueue(QueueName, Message) ->
    gen_server:call(?MODULE, {enqueue, QueueName, Message}).

dequeue(QueueName) ->
    gen_server:call(?MODULE, {dequeue, QueueName}).

list_queues() ->
    gen_server:call(?MODULE, list_queues).

init([]) ->
    {ok, #state{}}.

handle_call({enqueue, QueueName, Message}, _From, State = #state{queues = Queues}) ->
    UpdatedQueues = maps:update_with(QueueName, 
        fun(Queue) -> queue:in(Message, Queue) end, 
        queue:new(), 
        Queues
    ),
    {reply, ok, State#state{queues = UpdatedQueues}};

handle_call({dequeue, QueueName}, _From, State = #state{queues = Queues}) ->
    case maps:find(QueueName, Queues) of
        {ok, Queue} ->
            case queue:out(Queue) of
                {{value, Message}, NewQueue} ->
                    UpdatedQueues = maps:update(QueueName, NewQueue, Queues),
                    {reply, {ok, Message}, State#state{queues = UpdatedQueues}};
                {empty, _} ->
                    {reply, {error, empty_queue}, State}
            end;
        error ->
            {reply, {error, queue_not_found}, State}
    end;

handle_call(list_queues, _From, State = #state{queues = Queues}) ->
    {reply, maps:keys(Queues), State}.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.
