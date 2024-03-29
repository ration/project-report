FROM ruby:2-alpine3.13
COPY Gemfile .
COPY bin/project-report .
RUN apk --update add --virtual build_deps openssl icu openssl-dev build-base icu-dev cmake \
    && gem install bundler && bundler install
CMD ["/project-report"]
