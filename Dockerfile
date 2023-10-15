FROM ruby:3.2.2
LABEL authors="rexkimta@gmail.com"
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