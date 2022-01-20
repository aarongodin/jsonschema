# Provides string format validations for any allowed "format" keyword.
module JSONSchema::Format
  extend self

  def is_date_time(value : String)
    true
  end

  def is_time(value : String)
    true
  end

  def is_date(value : String)
    true
  end

  def is_duration(value : String)
    true
  end

  def is_email(value : String)
    true
  end

  def is_idn_email(value : String)
    true
  end

  def is_hostname(value : String)
    true
  end

  def is_idn_hostname(value : String)
    true
  end

  def is_ipv4(value : String)
    true
  end

  def is_ipv6(value : String)
    true
  end

  def is_uuid(value : String)
    true
  end

  def is_uri(value : String)
    true
  end

  def is_uri_reference(value : String)
    true
  end

  def is_iri(value : String)
    true
  end

  def is_iri_reference(value : String)
    true
  end

  def is_json_pointer(value : String)
    true
  end

  def is_relative_json_pointer(value : String)
    true
  end

  def is_regex(value : String)
    true
  end
end
