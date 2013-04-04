require 'active_support/core_ext/array/conversions'

require 'tags/tags'
require 'ruby-bbcode/debugging'
require 'ruby-bbcode/tag_info'
require 'ruby-bbcode/tag_sifter'
require 'ruby-bbcode/tag_node'
require 'ruby-bbcode/tag_collection'
require 'ruby-bbcode/bbtree'

module RubyBBCode
  include ::RubyBBCode::Tags

  # FIXME:  This needs documentation
  def self.to_html(text, escape_html = true, additional_tags = {}, method = :disable, *tags)
    text = text.clone
    
    use_tags = determine_applicable_tags(additional_tags, method, *tags)
    
    # TODO:  Move this inside tag_sifter as an optional parameter upon initialization maybe?
    if escape_html
      text.gsub!('<', '&lt;')
      text.gsub!('>', '&gt;')
    end

    valid = parse(text, use_tags)
    raise valid.join(', ') if valid != true   # We cannot convert to HTML if the BBCode is not valid!
    
    @tag_sifter.bbtree.to_html(use_tags)
  end

  def self.is_valid?(text, additional_tags = {})
    parse(text, @@tags.merge(additional_tags));  
  end
  
  
  protected
  
  # FIXME: this code needs to possibly have a better name and needs comments.  idk what it does...
  def self.determine_applicable_tags(additional_tags, method, *tags)
    use_tags = @@tags.merge(additional_tags)
    if method == :disable then          # if user specified :disable
      tags.each { |t| use_tags.delete(t) }   # disable tags supplied??
    else  # user specified...????
      new_use_tags = {}
      tags.each { |t| new_use_tags[t] = use_tags[t] if use_tags.key?(t) }
      use_tags = new_use_tags
    end
    use_tags
  end
  
  def self.parse(text, tags)
    @tag_sifter = TagSifter.new(text, tags)
    
    @tag_sifter.process_text
    
    if @tag_sifter.invalid?
      @tag_sifter.errors 
    else
      true
    end
    
  end

end

String.class_eval do
  # Convert a string with BBCode markup into its corresponding HTML markup
  def bbcode_to_html(escape_html = true, additional_tags = {}, method = :disable, *tags)
    RubyBBCode.to_html(self, escape_html, additional_tags, method, *tags)
  end
  
  # Replace the BBCode content of a string with its corresponding HTML markup
  def bbcode_to_html!(escape_html = true, additional_tags = {}, method = :disable, *tags)
    self.replace(RubyBBCode.to_html(self, escape_html, additional_tags, method, *tags))
  end

  # Check if string contains valid BBCode. Returns true when valid, else returns array with error(s)
  def is_valid_bbcode?
    RubyBBCode.is_valid?(self)
  end
end
