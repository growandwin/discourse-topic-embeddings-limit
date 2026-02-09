# frozen_string_literal: true

module ::HowicuredTopicEmbeddingsLimit
  def self.max_chars
    SiteSetting.howicured_topic_embeddings_limit_max_chars.to_i
  end

  # Narastająco: title + posty od początku aż do limitu
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
end

if defined?(::DiscourseAi::Embeddings::Vector)
  module ::HowicuredTopicEmbeddingsLimit::VectorPatch
    def generate_representation_from(target)
      # target może być Topic albo Post (wg joba)
      if SiteSetting.howicured_topic_embeddings_limit_enabled && target.is_a?(::Topic)
        # zamiast vdef.prepare_target_text(topic) bierzemy własną, limitowaną wersję
        text = ::HowicuredTopicEmbeddingsLimit.limited_topic_text(target)
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

  ::DiscourseAi::Embeddings::Vector.prepend(::HowicuredTopicEmbeddingsLimit::VectorPatch)
end
