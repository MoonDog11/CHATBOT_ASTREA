FROM ubuntu:jammy

# Add the PostgreSQL Apt Repository for PostgreSQL packages
RUN apt-get update && \
    apt-get install -y gnupg wget && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    echo "deb http://apt.postgresql.org/pub/repos/apt/ $(grep UBUNTU_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list

# Install postgresql-client-16 and other dependencies
RUN apt-get update && \
    apt-get install -y postgresql-client-16 bash ncurses-bin curl && \
    rm -rf /var/lib/apt/lists/*

# Install Node.js (LTS version 18.x)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get install -y nodejs

WORKDIR /app

# Copy application files
COPY . .

# Install application dependencies
RUN npm install

# Copy and set permissions for the init script
COPY init.sh /app/
RUN chmod +x /app/init.sh

# Run the init script
CMD ["/app/init.sh"]


