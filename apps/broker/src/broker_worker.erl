-module(broker_worker).
-behaviour(gen_server).

-export([start_link/1, init/1, handle_call/3, handle_cast/2, handle_info/2, terminate/2, code_change/3]).
-export([process_message/2, add_processor/2]).

-record(state, {
    queue_name,
    processors = #{}
}).

start_link(QueueName) ->
    gen_server:start_link({local, list_to_atom(atom_to_list(?MODULE) ++ "_" ++ atom_to_list(QueueName))}, ?MODULE, [QueueName], []).

add_processor(WorkerPid, {MessageType, ProcessorFun}) ->
    gen_server:call(WorkerPid, {add_processor, MessageType, ProcessorFun}).

process_message(WorkerPid, Message) ->
    gen_server:cast(WorkerPid, {process_message, Message}).

init([QueueName]) ->
    {ok, _} = timer:send_interval(1000, process_queue),
    {ok, #state{queue_name = QueueName}}.

handle_call({add_processor, MessageType, ProcessorFun}, _From, State = #state{processors = Processors}) ->
    UpdatedProcessors = maps:put(MessageType, ProcessorFun, Processors),
    {reply, ok, State#state{processors = UpdatedProcessors}}.

handle_cast({process_message, Message}, State) ->
    handle_message(Message, State),
    {noreply, State}.

handle_info(process_queue, State = #state{queue_name = QueueName, processors = Processors}) ->
    case broker_queue:dequeue(QueueName) of
        {ok, Message} ->
            handle_message(Message, State);
        {error, empty_queue} ->
            ok
    end,
    {noreply, State}.

handle_message(Message, #state{processors = Processors}) ->
    try
        {MessageType, _} = Message,
        
        case maps:find(MessageType, Processors) of
            {ok, ProcessorFun} ->
                ProcessorFun(Message);
            error ->
                error_logger:warning_msg("No processor found for message type ~p~n", [MessageType])
        end
    catch
        Class:Reason:Stacktrace ->
            error_logger:error_msg("Error processing message: ~p~n Reason: ~p~n Stacktrace: ~p~n", 
                                   [Message, {Class, Reason}, Stacktrace])
    end.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

% Usage example
example_usage() ->
    % Create a worker for messages queue
    {ok, WorkerPid} = broker_worker:start_link(my_queue),
    
    % Add processor for a message type
    broker_worker:add_processor(WorkerPid, {
        log_message, 
        fun({log_message, LogData}) -> 
            % Logique de traitement du message
            error_logger:info_msg("Received log: ~p", [LogData]) 
        end
    }),
    
    % Send message to queue
    broker_queue:enqueue(my_queue, {log_message, "a log message"}).