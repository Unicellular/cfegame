FROM ruby:3.2.2
LABEL authors="rexkimta@gmail.com"
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
ENV NODE_VERSION=20.18.0
ENV NVM_DIR=/root/.nvm
RUN . "$NVM_DIR/nvm.sh" && nvm install ${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm use v${NODE_VERSION}
RUN . "$NVM_DIR/nvm.sh" && nvm alias default v${NODE_VERSION}
ENV PATH="/root/.nvm/versions/node/v${NODE_VERSION}/bin/:${PATH}"
RUN npm install -g yarn
RUN yarn -v
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
ENV RAILS_ENV production
RUN bundle install
COPY . /app
RUN rails assets:precompile
ARG MASTER_KEY
ENV RAILS_MASTER_KEY=${MASTER_KEY}
# Get stuff running
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD rails s