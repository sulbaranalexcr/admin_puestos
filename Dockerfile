FROM ruby:2.5

WORKDIR /app
COPY . .
RUN apt-get update -yqq \
  && apt-get install -yqq --no-install-recommends \
  postgresql-client nodejs \
  nano \
  && rm -rf /var/lib/apt/lists
ENV TZ=America/Caracas
RUN gem install bundler -v 2.3.26
RUN bundle install
# ENV RAILS_ENV=production
#RUN bundle exec rails assets:precompile
EXPOSE 4000
CMD ["rails", "server", "-b", "0.0.0.0", "-p", "4000"]


# docker build . -t puestos_admin
# docker run -p 4000:4000 -e POSTGRES_HOST='10.0.4.1' puestos_admin
