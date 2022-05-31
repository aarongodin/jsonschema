require "validator"

date_time = /^\d{4}-(?:0[0-9]{1}|1[0-2]{1})-(3[01]|0[1-9]|[12][0-9])[tT ](2[0-4]|[01][0-9]):([0-5][0-9]):(60|[0-5][0-9])(\.\d+)?([zZ]|[+-]([0-5][0-9]):(60|[0-5][0-9]))$/
date = /^\d{4}-(?:0[0-9]{1}|1[0-2]{1})-(3[01]|0[1-9]|[12][0-9])$/
time = /^(2[0-4]|[01][0-9]):([0-5][0-9]):(60|[0-5][0-9])$/
duration = /P(T\d+(H(\d+M(\d+S)?)?|M(\d+S)?|S)|\d+(D|M(\d+D)?|Y(\d+M(\d+D)?)?)(T\d+(H(\d+M(\d+S)?)?|M(\d+S)?|S))?|\d+W)/i

json_pointer = /^(\/([\x00-\x2e0-@\[-}\x7f]|~[01])*)*$/i
relative_json_pointer = /^\d+(#|(\/([\x00-\x2e0-@\[-}\x7f]|~[01])*)*)$/i

hostname = /^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/

# Provides string format validations for any allowed `format` keyword.
module JSONSchema::Format
  extend self

  def is_date_time(value : String)
    !(date_time =~ value).nil?
  end

  def is_time(value : String)
    !(time =~ value).nil?
  end

  def is_date(value : String)
    !(date =~ value).nil?
  end

  def is_duration(value : String)
    !(duration =~ value).nil?
  end

  def is_email(value : String)
    Valid.email? value
  end

  def is_idn_email(value : String)
    raise "not implemented"
  end

  def is_hostname(value : String)
    !(hostname =~ value).nil?
  end

  def is_idn_hostname(value : String)
    raise "not implemented"
  end

  def is_ipv4(value : String)
    Valid.ipv4? value
  end

  def is_ipv6(value : String)
    Valid.ipv6? value
  end

  def is_uuid(value : String)
    Valid.uuid? value
  end

  # No URI validator at the moment; uses URL
  def is_uri(value : String)
    Valid.url? value
  end

  def is_uri_reference(value : String)
    raise "not implemented"
  end

  def is_iri(value : String)
    raise "not implemented"
  end

  def is_iri_reference(value : String)
    raise "not implemented"
  end

  def is_json_pointer(value : String)
    !(json_pointer =~ value).nil?
  end

  def is_relative_json_pointer(value : String)
    !(relative_json_pointer =~ value).nil?
  end

  def is_regex(value : String)
    Regex.new(value).is_a?(Regex) rescue false
  end
end
