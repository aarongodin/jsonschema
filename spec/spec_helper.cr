require "spec"
require "../src/json_schema"

def assert_validation_success(result : JSONSchema::ValidationResult)
  result.status.should eq(:success)
  result.errors.size.should eq(0)
end

def assert_validation_error(result : JSONSchema::ValidationResult, message : String)
  result.status.should eq(:error)
  result.errors.size.should eq(1)
  result.errors[0].message.should eq(message)
end

def assert_validation_errors(result : JSONSchema::ValidationResult, messages : Array(String))
  result.status.should eq(:error)
  result.errors.size.should eq(messages.size)
  result.errors.each_with_index do |error, i|
    error.message.should eq(messages[i])
  end
end

def assert_validation_error_context(result : JSONSchema::ValidationResult, contextPath : String)
  result.status.should eq(:error)
  result.errors.size.should eq(1)
  result.errors[0].context.to_s.should eq(contextPath)
end
