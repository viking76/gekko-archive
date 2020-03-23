FROM node:10

ENV HOST localhost
ENV PORT 3000
ENV MEMORYNODE 2048
ENV USE_SSL 0

# Add some extra tool
RUN apt-get update && \
    apt-get install nano
    # Clean
RUN apt-get clean && \
    apt-get autoclean
RUN rm -rf /var/lib/apt/lists/*

# Create app directory
RUN mkdir -p /usr/src/app
WORKDIR /usr/src/app 

# Install GYP dependencies globally, will be used to code build other dependencies
RUN npm install -g --production node-gyp && \
    npm cache clean --force

# Install Gekko dependencies
COPY package.json .
RUN npm install --production && \
    npm install --production redis talib tulind pg convnetjs mathjs && \
    npm cache clean --force

# Install Gekko Broker dependencies
WORKDIR exchange
COPY exchange/package.json .
RUN npm install --production && \
    npm cache clean --force
WORKDIR ../

# Install cpanminus.
RUN curl -L http://cpanmin.us | perl - App::cpanminus

# Install perl dependencies for Gekko-BacktestTool.
RUN cpanm -n install Parallel::ForkManager Time::Elapsed Getopt::Long List::MoreUtils File::chdir Statistics::Basic DBI DBD::SQLite JSON::XS TOML File::Basename File::Find::Wanted Template LWP::UserAgent LWP::Protocol::https Set::CrossProduct DBD::CSV Text::Table File::Copy

# Bundle app source
COPY . /usr/src/app

# Update Gekko strategies

RUN git clone https://github.com/xFFFFF/Gekko-Strategies
WORKDIR ./Gekko-Strategies
    RUN bash ./install.sh /usr/src/app
WORKDIR ../
RUN rm -R Gekko-Strategies

# add Neuralnet zchro 
RUN git clone https://github.com/zschro/gekko-neuralnet.git
WORKDIR ./gekko-neuralnet
    RUN cp ../install.sh . && \
    bash ./install.sh /usr/src/app
WORKDIR ../
RUN rm -R ./gekko-neuralnet

# Install Gekko BacktestTool
#WORKDIR ./Gekko-BacktestTool
RUN git clone https://github.com/xFFFFF/Gekko-BacktestTool.git
WORKDIR ./Gekko-BacktestTool
RUN cp *.* ..
WORKDIR ../
RUN rm -R ./Gekko-BacktestTool

# Install Genetic Algorithm for solving optimization of trading strategies using Gekko
RUN git clone https://github.com/gekkowarez/gekkoga.git
WORKDIR ./gekkoga
    RUN npm install 
WORKDIR ../

# Install Gekko Automated Backtest
RUN git clone https://github.com/tommiehansen/gab.git


EXPOSE 3000
RUN chmod +x /usr/src/app/docker-entrypoint.sh
ENTRYPOINT ["/usr/src/app/docker-entrypoint.sh"]

CMD ["--config", "/usr/src/app/configjs/config.js"]
