FROM swift:6.0

WORKDIR /app

# Copy Swift package definition
COPY ./Package.swift ./

# Copy source code
COPY ./Sources ./Sources
COPY ./Tests ./Tests

# Build the application
RUN swift build -c release

# Set the entrypoint to run the server
ENTRYPOINT ["./.build/release/MCP2Lambda"]
