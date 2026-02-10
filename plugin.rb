# frozen_string_literal: true

# name: discourse-topic-embeddings-limit
# about: Limit Topic embeddings input size for Discourse-AI
# version: 0.1.2
# authors: growandwin
# url: https://github.com/growandwin/discourse-topic-embeddings-limit

enabled_site_setting :topic_embeddings_limit_enabled

after_initialize do
  require_relative "lib/topic_embeddings_limit/patch"
end