# frozen_string_literal: true

# name: discourse-topic-embeddings-limit
# about: Limits Topic embeddings input size for Discourse-AI to prevent 8k token errors
# version: 0.1.0
# authors: Howicured
# url: https://github.com/growandwin/discourse-topic-embeddings-limit

enabled_site_setting :howicured_topic_embeddings_limit_enabled

register_setting(
  name: "howicured_topic_embeddings_limit_enabled",
  default: true,
  type: "bool"
)

register_setting(
  name: "howicured_topic_embeddings_limit_max_chars",
  default: 20000,
  type: "integer"
)

after_initialize do
  require_relative "lib/howicured_topic_embeddings_limit/vector_patch"
end
