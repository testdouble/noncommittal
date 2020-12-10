require "test_helper"

class NoncommittalTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Noncommittal::VERSION
  end
end
