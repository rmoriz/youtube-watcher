ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}

RUN apk add --update --no-cache ruby-dev build-base \
  libxml2-dev libxslt-dev pcre-dev libffi-dev \
  && gem install nokogiri -- --use-system-libraries \
  && gem install bundler --pre

RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

ENV RACK_ENV="production"

CMD ["puma", "-t 3:10", "-p4567"]

EXPOSE 4567
