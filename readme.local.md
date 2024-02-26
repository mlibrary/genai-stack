# Messy experimentation going on here

Hi folks.  This represents some of my experimentation with generative AI.

## Some observations
* The examples in the upstream repository are all python / Neo4j / ollama.

    I can cargo cult some python, but I'm more fluent in ruby right now.

* I've never used Neo4j before, but I've read that it's using Lucene, and I'm familiar with Solr which also uses Lucene.

    So I'm ignoring the Neo4j, and the python and adding containers for ruby and solr.

* The ollama stuff is mostly kept the same, but I did add a volume for it so that I don't have to redownload models when updating the container image.

* The `host-gateway` business seemed to not work for me out of the box.  I'm guessing they did that so that they wouldn't have to change the host name for the llm if the gpu-supported profile is being used.  I don't have a gpu so I'm just going to refer to the llm service internally.

## 

```bash
$ sudo chown -R 8983:8983 solr
$ docker-compose up -d llm solr
$ docker-compose up --no-start rb
$ docker-compose run --rm rb bundle install
$ docker-compose run --rm rb bundle exec ruby experiment2.rb
```

