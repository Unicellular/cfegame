FROM ruby:3.2.2
LABEL authors="rexkimta@gmail.com"
RUN mkdir /app
WORKDIR /app
COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
ENV RAILS_ENV production
RUN bundle install
COPY . /app
# Get stuff running
COPY docker-entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/docker-entrypoint.sh
ENTRYPOINT ["docker-entrypoint.sh"]
CMD rails s