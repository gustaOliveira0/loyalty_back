FROM ruby:3.2-slim

RUN apt-get update -qq && apt-get install -y \
  build-essential \
  libpq-dev \
  libyaml-dev \
  nodejs \
  postgresql-client \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

RUN chmod +x bin/docker-entrypoint.sh

EXPOSE 3000

ENTRYPOINT ["bin/docker-entrypoint.sh"]
