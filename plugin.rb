# frozen_string_literal: true

# name: discourse-topic-embeddings-limit
# about: Limit Topic embeddings input size for Discourse-AI
# version: 0.2.0
# authors: growandwin
# url: https://github.com/growandwin/discourse-topic-embeddings-limit

enabled_site_setting :topic_embeddings_limit_enabled

after_initialize do
  module ::TopicEmbeddingsLimit
    def self.max_chars
      SiteSetting.topic_embeddings_limit_max_chars.to_i
    end

    # Narastająco: title + posty od początku aż do limitu znaków
    def self.limited_topic_text(topic)
      limit = max_chars
      buf = +""

      title = topic.title.to_s.strip
      buf << title << "\n\n" if title.present?

      topic.posts.order(:post_number).each do |post|
        txt = post.raw.to_s.strip
        next if txt.blank?

        remaining = limit - buf.length
        break if remaining <= 0

        if txt.length <= remaining
          buf << txt << "\n\n"
        else
          buf << txt[0, remaining]
          break
        end
      end

      buf.gsub!(/\s+/, " ")
      buf.strip!
      buf
    end

    module VectorPatch
      def generate_representation_from(target)
        if SiteSetting.topic_embeddings_limit_enabled && target.is_a?(::Topic)
          text = ::TopicEmbeddingsLimit.limited_topic_text(target)
          return if text.blank?

          schema = ::DiscourseAi::Embeddings::Schema.for(target.class, vector_def: @vdef)

          new_digest = OpenSSL::Digest::SHA1.hexdigest(text)
          return if schema.find_by_target(target)&.digest == new_digest

          embeddings = @vdef.inference_client.perform!(text)
          schema.store(target, embeddings, new_digest)
          return
        end

        super
      end
    end
  end

  # Aplikuj patch tylko jeśli discourse-ai już załadował Vector
  if defined?(::DiscourseAi::Embeddings::Vector)
    ::DiscourseAi::Embeddings::Vector.prepend(::TopicEmbeddingsLimit::VectorPatch)
  else
    Rails.logger.warn("[discourse-topic-embeddings-limit] DiscourseAi::Embeddings::Vector not loaded yet; patch not applied")
  end
end
