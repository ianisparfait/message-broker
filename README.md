# Erlang Message Broker

## Overview

A lightweight, high-performance message broker implemented in Erlang, designed for efficient message queuing and processing with minimal complexity.

## Features

- Dynamic message queue management
- Flexible message processor registration
- Configurable logging
- Scalable architecture using OTP principles
- Lightweight alternative to complex message brokers like Kafka or RabbitMQ

## Prerequisites

- Erlang/OTP 24.0 or higher
- Rebar3

## Project Structure

```
message_broker/
├── apps/
│   └── broker/
│       ├── src/
│       │   ├── broker_app.erl
│       │   ├── broker_sup.erl
│       │   ├── broker_queue.erl
│       │   ├── broker_worker.erl
│       │   └── broker_client.erl
│       ├── ebin/
│       ├── priv/
│       └── test/
├── config/
│   ├── sys.config
│   └── vm.args
├── rebar.config
└── README.md
```

## Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/message_broker.git
   cd message_broker
   ```

2. Compile the project:
   ```bash
   rebar3 compile
   ```

3. Run the application:
   ```bash
   rebar3 shell
   ```

## Configuration

### System Configuration (`config/sys.config`)
- Logging settings
- Queue parameters
- Error handling configurations

### VM Arguments (`config/vm.args`)
- Erlang node naming
- Performance tuning
- Security settings

## Basic Usage Example

```erlang
% Create a queue
broker_queue:enqueue(my_queue, {log_message, "Hello, world!"}).

% Start a worker
{ok, WorkerPid} = broker_worker:start_link(my_queue).

% Add a message processor
broker_worker:add_processor(WorkerPid, {
    log_message, 
    fun({log_message, LogData}) -> 
        error_logger:info_msg("Received log: ~p", [LogData]) 
    end
}).
```

## Performance Considerations

- Designed for low-latency message processing
- Supports up to 262,144 processes
- Configurable scheduler and heap settings
- Generational garbage collection

## Monitoring

Utilizes `lager` for comprehensive logging:
- Console logs
- Rotated log files
- Error tracking
- Crash log management

## Testing

Run tests using:
```bash
rebar3 eunit
```

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Contact

Ianis PARFAIT - parfait.ianis@gmail.com

Project Link: [https://github.com/yourusername/message_broker](https://github.com/yourusername/message_broker)
