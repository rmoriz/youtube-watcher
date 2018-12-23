ARG RUBY_VERSION
FROM ruby:${RUBY_VERSION}

RUN apk add --update --no-cache ruby-dev build-base \
  libxml2-dev libxslt-dev pcre-dev libffi-dev \
  python3 \
  && gem install nokogiri -- --use-system-libraries \
  && gem install bundler --pre \
  && python3 -m ensurepip \
  && rm -r /usr/lib/python*/ensurepip \
  && pip3 install --upgrade pip setuptools streamlink \
  && adduser -S downloader -h /usr/src/app

WORKDIR /usr/src/app

COPY --chown=downloader:nogroup Gemfile Gemfile.lock ./
RUN bundle install

COPY --chown=downloader:nogroup . .

USER downloader

ENV RACK_ENV="production"

CMD ["ruby", "/usr/src/app/app.rb"]
