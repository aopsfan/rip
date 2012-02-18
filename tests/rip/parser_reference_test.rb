require_relative '../test_case'

class ParserReferenceLiteralTest < TestCase
  def test_reference
    [
      'name',
      'Person',
      '==',
      'save!',
      'valid?',
      'long_ref-name',
      '*/-+<>&$~%',
      'one_9'
    ].each do |reference|
      assert_equal reference, parser.reference.parse(reference)[:reference]
    end

    [
      'one.two',
      '6teen',
      'rip rocks'
    ].each do |reference|
      assert_raises Parslet::UnconsumedInput, Parslet::ParseFailed do
        parser.reference.parse(reference)
      end
    end
  end

  def test_assignment
    assignment = parser.assignment.parse('favorite_language = :rip')
    assert_equal 'favorite_language', assignment[:assignment][:reference]
    assert_equal 'rip', assignment[:assignment][:value][:string]
  end
end
