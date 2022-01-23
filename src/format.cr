DATE_TIME = /^\d{4}-(?:0[0-9]{1}|1[0-2]{1})-(3[01]|0[1-9]|[12][0-9])[tT ](2[0-4]|[01][0-9]):([0-5][0-9]):(60|[0-5][0-9])(\.\d+)?([zZ]|[+-]([0-5][0-9]):(60|[0-5][0-9]))$/
DATE      = /^\d{4}-(?:0[0-9]{1}|1[0-2]{1})-(3[01]|0[1-9]|[12][0-9])$/
TIME      = /^(2[0-4]|[01][0-9]):([0-5][0-9]):(60|[0-5][0-9])$/
DURATION  = /P(T\d+(H(\d+M(\d+S)?)?|M(\d+S)?|S)|\d+(D|M(\d+D)?|Y(\d+M(\d+D)?)?)(T\d+(H(\d+M(\d+S)?)?|M(\d+S)?|S))?|\d+W)/i

IPV4 = /^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$/
IPV6 = /^\s*((([0-9A-Fa-f]{1,4}:){7}([0-9A-Fa-f]{1,4}|:))|(([0-9A-Fa-f]{1,4}:){6}(:[0-9A-Fa-f]{1,4}|((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){5}(((:[0-9A-Fa-f]{1,4}){1,2})|:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3})|:))|(([0-9A-Fa-f]{1,4}:){4}(((:[0-9A-Fa-f]{1,4}){1,3})|((:[0-9A-Fa-f]{1,4})?:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){3}(((:[0-9A-Fa-f]{1,4}){1,4})|((:[0-9A-Fa-f]{1,4}){0,2}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){2}(((:[0-9A-Fa-f]{1,4}){1,5})|((:[0-9A-Fa-f]{1,4}){0,3}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(([0-9A-Fa-f]{1,4}:){1}(((:[0-9A-Fa-f]{1,4}){1,6})|((:[0-9A-Fa-f]{1,4}){0,4}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:))|(:(((:[0-9A-Fa-f]{1,4}){1,7})|((:[0-9A-Fa-f]{1,4}){0,5}:((25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)(\.(25[0-5]|2[0-4]\d|1\d\d|[1-9]?\d)){3}))|:)))(%.+)?\s*$/

URI  = /^[a-zA-Z][a-zA-Z0-9+.-]*:[^\s]*$/
IRI  = /^[a-zA-Z][a-zA-Z0-9+.-]*:[^\s]*$/
UUID = /^[0-9A-F]{8}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{12}$/i

JSON_POINTER          = /^(\/([\x00-\x2e0-@\[-}\x7f]|~[01])*)*$/i
RELATIVE_JSON_POINTER = /^\d+(#|(\/([\x00-\x2e0-@\[-}\x7f]|~[01])*)*)$/i

HOSTNAME = /^(?=.{1,255}$)[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?(?:\.[0-9A-Za-z](?:(?:[0-9A-Za-z]|-){0,61}[0-9A-Za-z])?)*\.?$/

# Provides string format validations for any allowed `format` keyword.
module JSONSchema::Format
  extend self

  def is_date_time(value : String)
    !(DATE_TIME =~ value).nil?
  end

  def is_time(value : String)
    !(TIME =~ value).nil?
  end

  def is_date(value : String)
    !(DATE =~ value).nil?
  end

  def is_duration(value : String)
    !(DURATION =~ value).nil?
  end

  def is_email(value : String)
    raise "not implemented"
  end

  def is_idn_email(value : String)
    raise "not implemented"
  end

  def is_hostname(value : String)
    !(HOSTNAME =~ value).nil?
  end

  def is_idn_hostname(value : String)
    raise "not implemented"
  end

  def is_ipv4(value : String)
    !(IPV4 =~ value).nil?
  end

  def is_ipv6(value : String)
    !(IPV6 =~ value).nil?
  end

  def is_uuid(value : String)
    !(UUID =~ value).nil?
  end

  def is_uri(value : String)
    !(URI =~ value).nil?
  end

  def is_uri_reference(value : String)
    raise "not implemented"
  end

  def is_iri(value : String)
    !(IRI =~ value).nil?
  end

  def is_iri_reference(value : String)
    raise "not implemented"
  end

  def is_json_pointer(value : String)
    !(JSON_POINTER =~ value).nil?
  end

  def is_relative_json_pointer(value : String)
    !(RELATIVE_JSON_POINTER =~ value).nil?
  end

  def is_regex(value : String)
    Regex.new(value).is_a?(Regex) rescue false
  end
end
