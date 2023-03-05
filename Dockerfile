FROM ruby:3.2.1-slim-bullseye

RUN mkdir -p /bot

WORKDIR /bot

COPY Gemfile .
COPY Gemfile.lock .

RUN bundle install

COPY main.rb .
