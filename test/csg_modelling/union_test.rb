require 'test_helper'

class UnionTest < Minitest::Test
  def test_union_construct
    c1 = cube(10)
    c2 = cube(20)

    u = Union.new(c1, c2)

    assert_equal 0, u.transformations.count
    assert_equal 2, u.children.count
    assert_equal c1, u.children[0]
    assert_equal c2, u.children[1]
  end

  def test_union_helper
    c1 = cube(10)
    c2 = cube(20)

    u = c1 + c2

    assert_equal 0, u.transformations.count
    assert_equal 2, u.children.count
    assert_equal c1, u.children[0]
    assert_equal c2, u.children[1]
  end

  # unions should be combined if they have no translations
  def test_union_optmize
    c1 = cube(10)
    c2 = cube(20)
    c3 = cube(30)

    u = c1 + c2 + c3

    # combined together
    assert_equal 0, u.transformations.count
    assert_equal 3, u.children.count
    assert_equal c1, u.children[0]
    assert_equal c2, u.children[1]
    assert_equal c3, u.children[2]

    # not combined, due to transformation
    u1 = c1 + c2
    u1.translate(z: 10)
    u2 = u1 + c3

    assert_equal 1, u1.transformations.count
    assert_equal 2, u1.children.count
    assert_equal c1, u1.children[0]
    assert_equal c2, u1.children[1]

    assert_equal 0, u2.transformations.count
    assert_equal 2, u1.children.count
    assert_equal u1, u2.children[0]
    assert_equal c3, u2.children[1]
  end

  def test_union_scad
    u = cube(10) + cube(20)

    exp = "union(){cube(size = [10, 10, 10]);\n" \
          "cube(size = [20, 20, 20]);\n" \
          '}'

    assert_equal exp, u.to_rubyscad
  end
end
