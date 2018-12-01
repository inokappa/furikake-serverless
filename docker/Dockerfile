FROM ruby:alpine
MAINTAINER inokappa
RUN apk update && \
    apk --no-chache --update add tzdata
WORKDIR /work
ADD ./ /work
RUN bundle install
