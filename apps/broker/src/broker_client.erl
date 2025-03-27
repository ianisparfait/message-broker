-module(broker_client).
-behaviour(gen_server).

% Public APIs
-export([
    start_link/0, 
    create_queue/1, 
    delete_queue/1, 
    publish/3, 
    subscribe/3, 
    unsubscribe/2,
    list_queues/0
]).

% Callbacks gen_server
-export([
    init/1, 
    handle_call/3, 
    handle_cast/2, 
    handle_info/2, 
    terminate/2, 
    code_change/3
]).

% Client state
-record(state, {
    queues = #{},           % Files de messages actives
    subscribers = #{}       % Abonnés par file de messages
}).

%% Public APIs

% Start the broker
start_link() ->
    gen_server:start_link({local, ?MODULE}, ?MODULE, [], []).

% Create a new message queue
create_queue(QueueName) ->
    gen_server:call(?MODULE, {create_queue, QueueName}).

% Publish a message in a queue
delete_queue(QueueName) ->
    gen_server:call(?MODULE, {delete_queue, QueueName}).

% Publier un message dans une file
publish(QueueName, MessageType, MessageContent) ->
    gen_server:call(?MODULE, {publish, QueueName, {MessageType, MessageContent}}).

% Subscribe to a message queue with a callback
subscribe(QueueName, MessageType, CallbackFun) ->
    gen_server:call(?MODULE, {subscribe, QueueName, MessageType, CallbackFun}).

% List existing message queues
unsubscribe(QueueName, MessageType) ->
    gen_server:call(?MODULE, {unsubscribe, QueueName, MessageType}).

% Lister les files de messages existantes
list_queues() ->
    gen_server:call(?MODULE, list_queues).

%% Callbacks gen_server

% Init
init([]) ->
    {ok, #state{}}.

% Create queue
handle_call({create_queue, QueueName}, _From, State = #state{queues = Queues}) ->
    case maps:is_key(QueueName, Queues) of
        false ->
            {ok, WorkerPid} = broker_worker:start_link(QueueName),
            UpdatedQueues = maps:put(QueueName, WorkerPid, Queues),
            {reply, {ok, WorkerPid}, State#state{queues = UpdatedQueues}};
        true ->
            {reply, {error, queue_already_exists}, State}
    end;

% Remove messages queue
handle_call({delete_queue, QueueName}, _From, State = #state{queues = Queues, subscribers = Subscribers}) ->
    case maps:find(QueueName, Queues) of
        {ok, WorkerPid} ->
            exit(WorkerPid, shutdown),
            
            UpdatedSubscribers = maps:remove(QueueName, Subscribers),
            UpdatedQueues = maps:remove(QueueName, Queues),
            
            {reply, ok, State#state{queues = UpdatedQueues, subscribers = UpdatedSubscribers}};
        error ->
            {reply, {error, queue_not_found}, State}
    end;

% Publish message
handle_call({publish, QueueName, Message}, _From, State = #state{queues = Queues}) ->
    case maps:find(QueueName, Queues) of
        {ok, _WorkerPid} ->
            broker_queue:enqueue(QueueName, Message),
            {reply, ok, State};
        error ->
            {reply, {error, queue_not_found}, State}
    end;

% Subscribe to queue
handle_call({subscribe, QueueName, MessageType, CallbackFun}, _From, 
            State = #state{queues = Queues, subscribers = Subscribers}) ->
    case maps:find(QueueName, Queues) of
        {ok, WorkerPid} ->
            ok = broker_worker:add_processor(WorkerPid, {MessageType, CallbackFun}),
            
            UpdatedSubscribers = maps:update_with(QueueName, 
                fun(TypeMap) -> 
                    maps:put(MessageType, CallbackFun, TypeMap) 
                end, 
                #{MessageType => CallbackFun}, 
                Subscribers
            ),
            
            {reply, ok, State#state{subscribers = UpdatedSubscribers}};
        error ->
            {reply, {error, queue_not_found}, State}
    end;

% Unsubscribe
handle_call({unsubscribe, QueueName, MessageType}, _From, 
            State = #state{subscribers = Subscribers}) ->
    UpdatedSubscribers = case maps:find(QueueName, Subscribers) of
        {ok, TypeMap} ->
            UpdatedTypeMap = maps:remove(MessageType, TypeMap),
            maps:update(QueueName, UpdatedTypeMap, Subscribers);
        error ->
            Subscribers
    end,
    
    {reply, ok, State#state{subscribers = UpdatedSubscribers}};


% List queues
handle_call(list_queues, _From, State = #state{queues = Queues}) ->
    {reply, maps:keys(Queues), State}.

% Generic callbacks
handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

terminate(_Reason, _State) ->
    ok.

code_change(_OldVsn, State, _Extra) ->
    {ok, State}.

%% Usage example
example_usage() ->
    {ok, _} = broker_client:start_link(),
    
    {ok, _WorkerPid} = broker_client:create_queue(notifications),
    
    ok = broker_client:subscribe(
        notifications, 
        email_notification, 
        fun({email_notification, EmailData}) -> 
            % Traitement de la notification par email
            send_email(EmailData) 
        end
    ),
    
    ok = broker_client:publish(
        notifications, 
        email_notification, 
        #{
            to => "user@example.com",
            subject => "Welcome",
            body => "Hello, welcome to our service!"
        }
    ),
    
    Queues = broker_client:list_queues().

% Dummy function for example (to be replaced by your email logic)
send_email(_EmailData) ->
    ok.